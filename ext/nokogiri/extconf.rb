ENV['RC_ARCHS'] = '' if RUBY_PLATFORM =~ /darwin/

# :stopdoc:

require 'mkmf'

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
LIBDIR = Config::CONFIG['libdir']
INCLUDEDIR = Config::CONFIG['includedir']

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'macruby'
  $LIBRUBYARG_STATIC.gsub!(/-static/, '')
end

$CFLAGS << " #{ENV["CFLAGS"]}"
$LIBS << " #{ENV["LIBS"]}"

if Config::CONFIG['target_os'] == 'mingw32'
  $CFLAGS << " -DXP_WIN -DXP_WIN32 -DUSE_INCLUDED_VASPRINTF"
elsif Config::CONFIG['target_os'] =~ /solaris/
  $CFLAGS << " -DUSE_INCLUDED_VASPRINTF"
else
  $CFLAGS << " -g -DXP_UNIX"
end

if RbConfig::MAKEFILE_CONFIG['CC'] =~ /mingw/
  $CFLAGS << " -DIN_LIBXML"
end

$CFLAGS << " -O3 -Wall -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"

HEADER_DIRS = [
  # First search /opt/local for macports
  '/opt/local/include',

  # Then search /usr/local for people that installed from source
  '/usr/local/include',

  # Check the ruby install locations
  INCLUDEDIR,

  # Finally fall back to /usr
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

dir_config('zlib', HEADER_DIRS, LIB_DIRS)
dir_config('iconv', HEADER_DIRS, LIB_DIRS)
dir_config('xml2', [
           '/opt/local/include/libxml2',
           '/usr/local/include/libxml2',
           File.join(INCLUDEDIR, "libxml2")] + HEADER_DIRS, LIB_DIRS)
dir_config('xslt', HEADER_DIRS, LIB_DIRS)

def asplode(lib)
  abort "-----\n#{lib} is missing.  please visit http://nokogiri.org/tutorials/installing_nokogiri.html for help with installing dependencies.\n-----"
end

# Use this with cross compiling
# PKG_CONFIG_PATH=/Users/apatterson/git/nokogiri/tmp/cross/lib/pkgconfig/ \
#   rake cross compile RUBY_CC_VERSION=1.9.1
pkg_config('libxslt') if RUBY_PLATFORM =~ /mingw/

asplode "libxml2"  unless find_header('libxml/parser.h')
asplode "libxslt"  unless find_header('libxslt/xslt.h')
asplode "libexslt" unless find_header('libexslt/exslt.h')
asplode "libxml2"  unless find_library('xml2', 'xmlParseDoc')
asplode "libxslt"  unless find_library('xslt', 'xsltParseStylesheetDoc')
asplode "libexslt" unless find_library('exslt', 'exsltFuncRegister')

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
