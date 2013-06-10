ENV['RC_ARCHS'] = '' if RUBY_PLATFORM =~ /darwin/

# :stopdoc:

require 'mkmf'

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
LIBDIR = RbConfig::CONFIG['libdir']
@libdir_basename = "lib" # shrug, ruby 2.0 won't work for me.
INCLUDEDIR = RbConfig::CONFIG['includedir']

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'macruby'
  $LIBRUBYARG_STATIC.gsub!(/-static/, '')
end

$CFLAGS << " #{ENV["CFLAGS"]}"
$LIBS << " #{ENV["LIBS"]}"

def preserving_globals
  values =
    $arg_config,
    $CFLAGS, $CPPFLAGS,
    $LDFLAGS, $LIBPATH, $libs
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

windows_p = RbConfig::CONFIG['target_os'] == 'mingw32' || RbConfig::CONFIG['target_os'] =~ /mswin/

if windows_p
  $CFLAGS << " -DXP_WIN -DXP_WIN32 -DUSE_INCLUDED_VASPRINTF"
elsif RbConfig::CONFIG['target_os'] =~ /solaris/
  $CFLAGS << " -DUSE_INCLUDED_VASPRINTF"
else
  $CFLAGS << " -g -DXP_UNIX"
end

if RbConfig::MAKEFILE_CONFIG['CC'] =~ /mingw/
  $CFLAGS << " -DIN_LIBXML"
  $LIBS << " -lz" # TODO why is this necessary?
end

if RbConfig::MAKEFILE_CONFIG['CC'] =~ /gcc/
  $CFLAGS << " -O3" unless $CFLAGS[/-O\d/]
  $CFLAGS << " -Wall -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"
end

if windows_p
  # I'm cross compiling!
  HEADER_DIRS = [INCLUDEDIR]
  LIB_DIRS = [LIBDIR]
  XML2_HEADER_DIRS = [File.join(INCLUDEDIR, "libxml2"), INCLUDEDIR]

else
  opt_header_dirs = [
    # First search /opt/local for macports
    '/opt/local/include',

    # Then search /usr/local for people that installed from source
    '/usr/local/include',

    # Check the ruby install locations
    INCLUDEDIR,
  ]

  if ENV['NOKOGIRI_USE_SYSTEM_LIBRARIES']
    HEADER_DIRS = opt_header_dirs + [
      # Fall back to /usr
      '/usr/include',
      '/usr/include/libxml2',
    ]

    LIB_DIRS = [
      # First search /opt/local for macports
      '/opt/local/lib',

      # Then search /usr/local for people that installed from source
      '/usr/local/lib',

      # Check the ruby install locations
      LIBDIR,

      # Finally fall back to /usr
      '/usr/lib',
    ]

    XML2_HEADER_DIRS = opt_header_dirs.map { |idir|
      File.join(idir, "libxml2")
    } + HEADER_DIRS

    # If the user has homebrew installed, use the libxml2 inside homebrew
    brew_prefix = `brew --prefix libxml2 2> /dev/null`.chomp
    unless brew_prefix.empty?
      LIB_DIRS.unshift File.join(brew_prefix, 'lib')
      XML2_HEADER_DIRS.unshift File.join(brew_prefix, 'include/libxml2')
    end

  else
    require 'mini_portile'
    require 'yaml'

    common_recipe = lambda do |recipe|
      recipe.target = File.join(ROOT, "ports")
      recipe.files = ["ftp://ftp.xmlsoft.org/libxml2/#{recipe.name}-#{recipe.version}.tar.gz"]

      checkpoint = "#{recipe.target}/#{recipe.name}-#{recipe.version}-#{recipe.host}.installed"
      unless File.exist?(checkpoint)
        recipe.cook
        FileUtils.touch checkpoint
      end
      recipe.activate
    end

    def each_idir
      # If --with-iconv-dir is given, it should be the first priority
      idir = preserving_globals {
        dir_config('iconv')
      }.first and yield idirta

      # Then --with-opt-dir
      idir = preserving_globals {
        dir_config('opt')
      }.first and yield idir

      # Try the system default
      yield "/usr/include"

      opt_header_dirs.each { |dir|
        yield dir
      }

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

    # Make sure libxml2 is built with iconv
    iconv_prefix = each_idir { |idir|
      prefix = %r{\A(.+)?/include\z} === idir && $1 or next
      File.exist?(File.join(idir, 'iconv.h')) or next
      preserving_globals {
        # Follow the way libxml2's configure uses a value given with
        # --with-iconv[=DIR]
        $CPPFLAGS << " -I#{idir}"
        $LDFLAGS  << " -L#{prefix}/lib"
        have_iconv?
      } and break prefix
    } or asplode "libiconv"

    dependencies = YAML.load_file(File.join(ROOT, "dependencies.yml"))

    libxml2_recipe = MiniPortile.new("libxml2", dependencies["libxml2"]).tap do |recipe|
      recipe.configure_options = [
        "--enable-shared",
        "--disable-static",
        "--without-python",
        "--without-readline",
        "--with-iconv=#{iconv_prefix}",
        "--with-c14n",
        "--with-debug",
        "--with-threads"
      ]
      common_recipe.call recipe
    end

    libxslt_recipe = MiniPortile.new("libxslt", dependencies["libxslt"]).tap do |recipe|
      recipe.configure_options = [
        "--enable-shared",
        "--disable-static",
        "--without-python",
        "--without-crypto",
        "--with-debug",
        "--with-libxml-prefix=#{libxml2_recipe.path}"
      ]
      common_recipe.call recipe
    end

    $LDFLAGS << " -Wl,-rpath,#{libxml2_recipe.path}/lib"
    $LDFLAGS << " -Wl,-rpath,#{libxslt_recipe.path}/lib"

    $CFLAGS << " -DNOKOGIRI_USE_PACKAGED_LIBRARIES -DNOKOGIRI_LIBXML2_PATH='\"#{libxml2_recipe.path}\"' -DNOKOGIRI_LIBXSLT_PATH='\"#{libxslt_recipe.path}\"'"

    HEADER_DIRS = [libxml2_recipe, libxslt_recipe].map { |f| File.join(f.path, "include") }
    LIB_DIRS = [libxml2_recipe, libxslt_recipe].map { |f| File.join(f.path, "lib") }
    XML2_HEADER_DIRS = HEADER_DIRS + [File.join(libxml2_recipe.path, "include", "libxml2")]
  end
end

dir_config('zlib', HEADER_DIRS, LIB_DIRS)
dir_config('iconv', HEADER_DIRS, LIB_DIRS)
dir_config('xml2', XML2_HEADER_DIRS, LIB_DIRS)
dir_config('xslt', HEADER_DIRS, LIB_DIRS)

pkg_config('libxslt')
pkg_config('libxml-2.0')
pkg_config('libiconv')

asplode "libxml2"  unless find_header('libxml/parser.h')
asplode "libxslt"  unless find_header('libxslt/xslt.h')
asplode "libexslt" unless find_header('libexslt/exslt.h')
asplode "libiconv" unless have_iconv?
asplode "libxml2"  unless find_library("xml2", 'xmlParseDoc')
asplode "libxslt"  unless find_library("xslt", 'xsltParseStylesheetDoc')
asplode "libexslt" unless find_library("exslt", 'exsltFuncRegister')

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

# :startdoc:
