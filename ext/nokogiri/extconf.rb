ENV['RC_ARCHS'] = '' if RUBY_PLATFORM =~ /darwin/

# :stopdoc:

require 'mkmf'

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
LIBDIR = RbConfig::CONFIG['libdir']
INCLUDEDIR = RbConfig::CONFIG['includedir']

$LIBRUBYARG_STATIC.gsub!(/-static/, '') if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'macruby'

$CFLAGS << " #{ENV['CFLAGS']}"
$LIBS << " #{ENV['LIBS']}"

$CFLAGS << if RbConfig::CONFIG['target_os'] == 'mingw32' || RbConfig::CONFIG['target_os'] =~ /mswin32/
             ' -DXP_WIN -DXP_WIN32 -DUSE_INCLUDED_VASPRINTF'
           elsif RbConfig::CONFIG['target_os'] =~ /solaris/
             ' -DUSE_INCLUDED_VASPRINTF'
           else
             ' -g -DXP_UNIX'
           end

$CFLAGS << ' -DIN_LIBXML' if RbConfig::MAKEFILE_CONFIG['CC'] =~ /mingw/

if RbConfig::MAKEFILE_CONFIG['CC'] =~ /gcc/
  $CFLAGS << ' -O3 -Wall -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline'
end

if RbConfig::CONFIG['target_os'] =~ /mswin32/
  lib_prefix = 'lib'

  # There's no default include/lib dir on Windows. Let's just add the Ruby ones
  # and resort on the search path specified by INCLUDE and LIB environment
  # variables
  HEADER_DIRS = [INCLUDEDIR].freeze
  LIB_DIRS = [LIBDIR].freeze
  XML2_HEADER_DIRS = [File.join(INCLUDEDIR, 'libxml2'), INCLUDEDIR].freeze

else
  lib_prefix = ''

  HEADER_DIRS = [
    # First search /opt/local for macports
    '/opt/local/include',

    # Then search /usr/local for people that installed from source
    '/usr/local/include',

    # Check the ruby install locations
    INCLUDEDIR,

    # Finally fall back to /usr
    '/usr/include',
    '/usr/include/libxml2'
  ].freeze

  LIB_DIRS = [
    # First search /opt/local for macports
    '/opt/local/lib',

    # Then search /usr/local for people that installed from source
    '/usr/local/lib',

    # Check the ruby install locations
    LIBDIR,

    # Finally fall back to /usr
    '/usr/lib'
  ].freeze

  XML2_HEADER_DIRS = [
    '/opt/local/include/libxml2',
    '/usr/local/include/libxml2',
    File.join(INCLUDEDIR, 'libxml2')
  ] + HEADER_DIRS
end

dir_config('zlib', HEADER_DIRS, LIB_DIRS)
dir_config('iconv', HEADER_DIRS, LIB_DIRS)
dir_config('xml2', XML2_HEADER_DIRS, LIB_DIRS)
dir_config('xslt', HEADER_DIRS, LIB_DIRS)

def asplode(lib)
  abort "-----\n#{lib} is missing.  please visit http://nokogiri.org/tutorials/installing_nokogiri.html for help with installing dependencies.\n-----"
end

pkg_config('libxslt') if RUBY_PLATFORM =~ /mingw/

asplode 'libxml2'  unless find_header('libxml/parser.h')
asplode 'libxslt'  unless find_header('libxslt/xslt.h')
asplode 'libexslt' unless find_header('libexslt/exslt.h')
asplode 'libiconv' unless have_func('iconv_open', 'iconv.h') || have_library('iconv', 'iconv_open', 'iconv.h')
asplode 'libxml2'  unless find_library("#{lib_prefix}xml2", 'xmlParseDoc')
asplode 'libxslt'  unless find_library("#{lib_prefix}xslt", 'xsltParseStylesheetDoc')
asplode 'libexslt' unless find_library("#{lib_prefix}exslt", 'exsltFuncRegister')

have_func 'xmlFirstElementChild'
have_func('xmlRelaxNGSetParserStructuredErrors')
have_func('xmlRelaxNGSetParserStructuredErrors')
have_func('xmlRelaxNGSetValidStructuredErrors')
have_func('xmlSchemaSetValidStructuredErrors')
have_func('xmlSchemaSetParserStructuredErrors')

if ENV['CPUPROFILE']
  abort 'google performance tools are not installed' unless find_library('profiler', 'ProfilerEnable', *LIB_DIRS)
end

create_makefile('nokogiri/nokogiri')
# :startdoc:
