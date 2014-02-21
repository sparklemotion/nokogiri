ENV['RC_ARCHS'] = '' if RUBY_PLATFORM =~ /darwin/

# Available options:
#
# --enable-clean (default)
# --disable-clean
#
# --enable-static (default)
# --disable-static
#
# --with-iconv-dir=DIR
#
# --with-zlib-dir=DIR
#
# --use-system-libraries
#   --with-xml2-dir=DIR / --with-xml2-config=CONFIG
#   --with-xslt-dir=DIR / --with-xslt-config=CONFIG
#   --with-exslt-dir=DIR / --with-exslt-config=CONFIG
#
# --enable-cross-build

# :stopdoc:

require 'mkmf'

def message!(important_message)
  message important_message
  if !$stdout.tty? && File.chardev?('/dev/tty')
    File.open('/dev/tty', 'w') { |tty|
      tty.print important_message
    }
  end
end

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
# Workaround for Ruby bug #8074, introduced in Ruby 2.0.0, fixed in Ruby 2.1.0
# https://bugs.ruby-lang.org/issues/8074
@libdir_basename = "lib"

if arg_config('--clean')
  require 'pathname'
  require 'fileutils'

  root = Pathname(ROOT)
  pwd  = Pathname(Dir.pwd)

  # Skip if this is a development work tree
  unless (root + '.git').exist?
    message "Cleaning files only used during build.\n"

    # (root + 'tmp') cannot be removed at this stage because
    # nokogiri.so is yet to be copied to lib.

    # clean the ports build directory
    Pathname.glob(pwd.join('tmp', '*', 'ports')) { |dir|
      FileUtils.rm_rf(dir, verbose: true)
      FileUtils.rmdir(dir.parent, parents: true, verbose: true)
    }

    if enable_config('static')
      # ports installation can be safely removed if statically linked.
      FileUtils.rm_rf(root + 'ports', verbose: true)
    else
      FileUtils.rm_rf(root + 'ports' + 'archives', verbose: true)
    end
  end

  exit
end

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'macruby'
  $LIBRUBYARG_STATIC.gsub!(/-static/, '')
end

$CFLAGS << " #{ENV["CFLAGS"]}"
$LIBS << " #{ENV["LIBS"]}"

def preserving_globals
  values = [
    $arg_config,
    $CFLAGS, $CPPFLAGS,
    $LDFLAGS, $LIBPATH, $libs
  ].map(&:dup)
  yield
ensure
  $arg_config,
  $CFLAGS, $CPPFLAGS,
  $LDFLAGS, $LIBPATH, $libs =
    values
end

def asplode(lib)
  abort "-----\n#{lib} is missing.  please visit http://nokogiri.org/tutorials/installing_nokogiri.html for help with installing dependencies.\n-----"
end

def have_iconv?
  have_header('iconv.h') or return false
  %w{ iconv_open libiconv_open }.any? do |method|
    have_func(method, 'iconv.h') or
      have_library('iconv', method, 'iconv.h')
  end
end

def each_iconv_idir
  # If --with-iconv-dir or --with-opt-dir is given, it should be
  # the first priority
  %w[iconv opt].each { |config|
    idir = preserving_globals {
      dir_config(config)
    }.first and yield idir
  }

  # Try the system default
  yield "/usr/include"

  cflags, = preserving_globals {
    pkg_config('libiconv')
  }
  if cflags
    cflags.shellsplit.each { |arg|
      arg.sub!(/\A-I/, '') and
      yield arg
    }
  end

  nil
end

def iconv_prefix
  # Make sure libxml2 is built with iconv
  each_iconv_idir { |idir|
    prefix = %r{\A(.+)?/include\z} === idir && $1 or next
    File.exist?(File.join(idir, 'iconv.h')) or next
    preserving_globals {
      # Follow the way libxml2's configure uses a value given with
      # --with-iconv[=DIR]
      $CPPFLAGS = "-I#{idir} " << $CPPFLAGS
      $LIBPATH.unshift(File.join(prefix, "lib"))
      have_iconv?
    } and break prefix
  } or asplode "libiconv"
end

def process_recipe(name, version, static_p, cross_p)
  MiniPortile.new(name, version).tap do |recipe|
    recipe.target = portsdir = File.join(ROOT, "ports")
    # Prefer host_alias over host in order to use i586-mingw32msvc as
    # correct compiler prefix for cross build, but use host if not set.
    recipe.host = RbConfig::CONFIG["host_alias"].empty? ? RbConfig::CONFIG["host"] : RbConfig::CONFIG["host_alias"]
    recipe.patch_files = Dir[File.join(portsdir, "patches", name, "*.patch")].sort

    if static_p
      recipe.configure_options = [
        "--disable-shared",
        "--enable-static",
        "CFLAGS='-fPIC #{ENV["CFLAGS"]}'",
      ]
    else
      recipe.configure_options = [
        "--enable-shared",
        "--disable-static",
      ]
    end

    if cross_p
      recipe.configure_options += [
        "--target=#{recipe.host}",
        "--host=#{recipe.host}",
      ]
    end

    yield recipe

    if recipe.patch_files.empty?
      message! "Building #{name}-#{version} for nokogiri.\n"
    else
      message! "Building #{name}-#{version} for nokogiri with the following patches applied:\n"

      recipe.patch_files.each { |patch|
        message! "\t- %s\n" % File.basename(patch)
      }
    end

    message! <<-"EOS"
************************************************************************
IMPORTANT!  Nokogiri builds and uses a packaged version of #{name}.

If this is a concern for you and you want to use the system library
instead, abort this installation process and reinstall nokogiri as
follows:

    gem install nokogiri -- --use-system-libraries

If you are using Bundler, tell it to use the option:

    bundle config build.nokogiri --use-system-libraries
    bundle install
    EOS

    message! <<-"EOS" if name == 'libxml2'

However, note that nokogiri does not necessarily support all versions
of libxml2.

For example, libxml2-2.9.0 and higher are currently known to be broken
and thus unsupported by nokogiri, due to compatibility problems and
XPath optimization bugs.
    EOS

    message! <<-"EOS"
************************************************************************
    EOS

    checkpoint = "#{recipe.target}/#{recipe.name}-#{recipe.version}-#{recipe.host}.installed"
    unless File.exist?(checkpoint)
      recipe.cook
      FileUtils.touch checkpoint
    end
    recipe.activate
  end
end

windows_p = RbConfig::CONFIG['target_os'] == 'mingw32' || RbConfig::CONFIG['target_os'] =~ /mswin/

if windows_p
  $CFLAGS << " -DXP_WIN -DXP_WIN32 -DUSE_INCLUDED_VASPRINTF"
elsif RbConfig::CONFIG['target_os'] =~ /solaris/
  $CFLAGS << " -DUSE_INCLUDED_VASPRINTF"
else
  $CFLAGS << " -g -DXP_UNIX"
end

if RbConfig::MAKEFILE_CONFIG['CC'] =~ /mingw/
  # Work around a character escaping bug in MSYS by passing an arbitrary
  # double quoted parameter to gcc. See https://sourceforge.net/p/mingw/bugs/2142
  $CPPFLAGS << ' "-Idummypath"'

  $CFLAGS << " -DIN_LIBXML"
  # Mingw32 package is static linked
  $LIBS << " -lz -liconv"
end

if RbConfig::MAKEFILE_CONFIG['CC'] =~ /gcc/
  $CFLAGS << " -O3" unless $CFLAGS[/-O\d/]
  $CFLAGS << " -Wall -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"
end

case
when arg_config('--use-system-libraries', !!ENV['NOKOGIRI_USE_SYSTEM_LIBRARIES'])
  message! "Building nokogiri using system libraries.\n"

  dir_config('zlib')

  # Using system libraries means we rely on the system libxml2 with
  # regard to the iconv support.

  dir_config('xml2').any?  || pkg_config('libxml-2.0')
  dir_config('xslt').any?  || pkg_config('libxslt')
  dir_config('exslt').any? || pkg_config('libexslt')
else
  message! "Building nokogiri using packaged libraries.\n"

  require 'mini_portile'
  require 'yaml'

  static_p = enable_config('static', true) or
    message! "Static linking is disabled.\n"

  dir_config('zlib')

  dependencies = YAML.load_file(File.join(ROOT, "dependencies.yml"))

  cross_build_p = enable_config("cross-build")
  if cross_build_p || windows_p
    zlib_recipe = process_recipe("zlib", dependencies["zlib"], static_p, cross_build_p) do |recipe|
      recipe.files = ["http://zlib.net/#{recipe.name}-#{recipe.version}.tar.gz"]
      class << recipe
        attr_accessor :cross_build_p

        def configure
          Dir.chdir work_path do
            mk = File.read 'win32/Makefile.gcc'
            File.open 'win32/Makefile.gcc', 'wb' do |f|
              f.puts "BINARY_PATH = #{path}/bin"
              f.puts "LIBRARY_PATH = #{path}/lib"
              f.puts "INCLUDE_PATH = #{path}/include"
              mk.sub!(/^PREFIX\s*=\s*$/, "PREFIX = #{host}-") if cross_build_p
              f.puts mk
            end
          end
        end

        def configured?
          Dir.chdir work_path do
            !! (File.read('win32/Makefile.gcc') =~ /^BINARY_PATH/)
          end
        end

        def compile
          execute "compile", "make -f win32/Makefile.gcc"
        end

        def install
          execute "install", "make -f win32/Makefile.gcc install"
        end
      end
      recipe.cross_build_p = cross_build_p
    end

    libiconv_recipe = process_recipe("libiconv", dependencies["libiconv"], static_p, cross_build_p) do |recipe|
      recipe.files = ["http://ftp.gnu.org/pub/gnu/libiconv/#{recipe.name}-#{recipe.version}.tar.gz"]
      recipe.configure_options += [
        "CPPFLAGS='-Wall'",
        "CFLAGS='-O2 -g'",
        "CXXFLAGS='-O2 -g'",
        "LDFLAGS="
      ]
    end
  end

  libxml2_recipe = process_recipe("libxml2", dependencies["libxml2"], static_p, cross_build_p) do |recipe|
    recipe.files = ["ftp://ftp.xmlsoft.org/libxml2/#{recipe.name}-#{recipe.version}.tar.gz"]
    recipe.configure_options += [
      "--without-python",
      "--without-readline",
      "--with-iconv=#{libiconv_recipe ? libiconv_recipe.path : iconv_prefix}",
      "--with-c14n",
      "--with-debug",
      "--with-threads"
    ]
  end

  libxslt_recipe = process_recipe("libxslt", dependencies["libxslt"], static_p, cross_build_p) do |recipe|
    recipe.files = ["ftp://ftp.xmlsoft.org/libxml2/#{recipe.name}-#{recipe.version}.tar.gz"]
    recipe.configure_options += [
      "--without-python",
      "--without-crypto",
      "--with-debug",
      "--with-libxml-prefix=#{libxml2_recipe.path}"
    ]
  end

  $CFLAGS << ' ' << '-DNOKOGIRI_USE_PACKAGED_LIBRARIES'
  $LIBPATH = ["#{zlib_recipe.path}/lib"] | $LIBPATH if zlib_recipe
  $LIBPATH = ["#{libiconv_recipe.path}/lib"] | $LIBPATH if libiconv_recipe

  have_lzma = preserving_globals {
    have_library('lzma')
  }

  $libs = $libs.shellsplit.tap { |libs|
    [libxml2_recipe, libxslt_recipe].each { |recipe|
      libname = recipe.name[/\Alib(.+)\z/, 1]
      File.join(recipe.path, "bin", "#{libname}-config").tap { |config|
        # call config scripts explicit with 'sh' for compat with Windows
        $CPPFLAGS = `sh #{config} --cflags`.strip << ' ' << $CPPFLAGS
        `sh #{config} --libs`.strip.shellsplit.each { |arg|
          case arg
          when /\A-L(.+)\z/
            # Prioritize ports' directories
            if $1.start_with?(ROOT + '/')
              $LIBPATH = [$1] | $LIBPATH
            else
              $LIBPATH = $LIBPATH | [$1]
            end
          when /\A-l./
            libs.unshift(arg)
          else
            $LDFLAGS << ' ' << arg.shellescape
          end
        }
      }

      $CPPFLAGS << ' ' << "-DNOKOGIRI_#{recipe.name.upcase}_PATH=\"#{recipe.path}\"".shellescape

      case libname
      when 'xml2'
        # xslt-config --libs or pkg-config libxslt --libs does not include
        # -llzma, so we need to add it manually when linking statically.
        if static_p && have_lzma
          # Add it at the end; GH #988
          libs << '-llzma'
        end
      when 'xslt'
        # xslt-config does not have a flag to emit options including
        # -lexslt, so add it manually.
        libs.unshift('-lexslt')
      end
    }
  }.shelljoin

  if static_p
    message 'checking for linker flags for static linking... '

    case
    when try_link('int main(void) { return 0; }',
                  ['-Wl,-Bstatic', '-lxml2', '-Wl,-Bdynamic'].shelljoin)
      message "-Wl,-Bstatic\n"

      $libs = $libs.shellsplit.flat_map { |arg|
        case arg
        when '-lxml2', '-lxslt', '-lexslt'
          ['-Wl,-Bstatic', arg, '-Wl,-Bdynamic']
        else
          arg
        end
      }.shelljoin
    else
      message "NONE\n"
    end
  end
end

{
  "xml2"  => ['xmlParseDoc',            'libxml/parser.h'],
  "xslt"  => ['xsltParseStylesheetDoc', 'libxslt/xslt.h'],
  "exslt" => ['exsltFuncRegister',      'libexslt/exslt.h'],
}.each { |lib, (func, header)|
  have_func(func, header) || have_library(lib, func, header) || have_library("lib#{lib}", func, header) or asplode("lib#{lib}")
}

unless have_func('xmlHasFeature')
  abort "-----\nThe function 'xmlHasFeature' is missing from your installation of libxml2.  Likely this means that your installed version of libxml2 is old enough that nokogiri will not work well.  To get around this problem, please upgrade your installation of libxml2.

Please visit http://nokogiri.org/tutorials/installing_nokogiri.html for more help!"
end

have_func 'xmlFirstElementChild'
have_func('xmlRelaxNGSetParserStructuredErrors')
have_func('xmlRelaxNGSetParserStructuredErrors')
have_func('xmlRelaxNGSetValidStructuredErrors')
have_func('xmlSchemaSetValidStructuredErrors')
have_func('xmlSchemaSetParserStructuredErrors')

if ENV['CPUPROFILE']
  unless find_library('profiler', 'ProfilerEnable', *LIB_DIRS)
    abort "google performance tools are not installed"
  end
end

create_makefile('nokogiri/nokogiri')

if enable_config('clean', true)
  # Do not clean if run in a development work tree.
  File.open('Makefile', 'at') { |mk|
    mk.print <<EOF
all: clean-ports

clean-ports: $(DLLIB)
	-$(Q)$(RUBY) $(srcdir)/extconf.rb --clean --#{static_p ? 'enable' : 'disable'}-static
EOF
  }
end

# :startdoc:
