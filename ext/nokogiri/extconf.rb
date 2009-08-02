ENV['RC_ARCHS'] = '' if RUBY_PLATFORM =~ /darwin/

# :stopdoc:

require 'mkmf'

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
LIBDIR = Config::CONFIG['libdir']
INCLUDEDIR = Config::CONFIG['includedir']

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'macruby'
  $LIBRUBYARG_STATIC.gsub!(/-static/, '')
end

$CFLAGS << " #{ENV["CFLAGS"]}"
if Config::CONFIG['target_os'] == 'mingw32'
  $CFLAGS << " -DXP_WIN -DXP_WIN32 -DUSE_INCLUDED_VASPRINTF"
elsif Config::CONFIG['target_os'] == 'solaris2'
  $CFLAGS << " -DUSE_INCLUDED_VASPRINTF"
else
  $CFLAGS << " -g -DXP_UNIX"
end

$CFLAGS << " -O3 -Wall -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"

HEADER_DIRS = [
  # First search /opt/local for macports
  '/opt/local/include',
  '/opt/local/include/libxml2',

  # Then search /usr/local for people that installed from source
  '/usr/local/include',
  '/usr/local/include/libxml2',

  # Check the ruby install locations
  INCLUDEDIR,
  File.join(INCLUDEDIR, "libxml2"),

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

iconv_dirs = dir_config('iconv', '/opt/local/include', '/opt/local/lib')
unless ["", ""] == iconv_dirs
  HEADER_DIRS.unshift iconv_dirs.first
  LIB_DIRS.unshift iconv_dirs[1]
end

xml2_dirs = dir_config('xml2', '/opt/local/include/libxml2', '/opt/local/lib')
unless ["", ""] == xml2_dirs
  HEADER_DIRS.unshift xml2_dirs.first
  LIB_DIRS.unshift xml2_dirs[1]
end

xslt_dirs = dir_config('xslt', '/opt/local/include/', '/opt/local/lib')
unless ["", ""] == xslt_dirs
  HEADER_DIRS.unshift xslt_dirs.first
  LIB_DIRS.unshift xslt_dirs[1]
end

CUSTOM_DASH_I = []

def nokogiri_find_header header_file, *paths
  # mkmf in ruby 1.8.5 does not have the "checking_message" method
  message = defined?(checking_message) ?
    checking_message(header_file, paths) :
    header_file

  header = cpp_include header_file
  checking_for message do
    found = false
    paths.each do |dir|
      if File.exists?(File.join(dir, header_file))
        opt = "-I#{dir}".quote
        if try_cpp header, opt
          unless CUSTOM_DASH_I.include? dir
            $INCFLAGS = "#{opt} #{$INCFLAGS}"
            CUSTOM_DASH_I << dir
          end
          found = dir
          break
        end
      end
    end
    found ||= try_cpp(header)
  end
end

unless nokogiri_find_header('iconv.h', *HEADER_DIRS)
  abort "iconv is missing.  try 'port install iconv' or 'yum install iconv'"
end

unless nokogiri_find_header('libxml/parser.h', *HEADER_DIRS)
  abort "libxml2 is missing.  try 'port install libxml2' or 'yum install libxml2-devel'"
end

unless nokogiri_find_header('libxslt/xslt.h', *HEADER_DIRS)
  abort "libxslt is missing.  try 'port install libxslt' or 'yum install libxslt-devel'"
end

unless nokogiri_find_header('libexslt/exslt.h', *HEADER_DIRS)
  abort "libxslt is missing.  try 'port install libxslt' or 'yum install libxslt-devel'"
end

unless find_library('xml2', 'xmlParseDoc', *LIB_DIRS)
  abort "libxml2 is missing.  try 'port install libxml2' or 'yum install libxml2'"
end

unless find_library('xslt', 'xsltParseStylesheetDoc', *LIB_DIRS)
  abort "libxslt is missing.  try 'port install libxslt' or 'yum install libxslt-devel'"
end

unless find_library('exslt', 'exsltFuncRegister', *LIB_DIRS)
  abort "libxslt is missing.  try 'port install libxslt' or 'yum install libxslt-devel'"
end

def nokogiri_link_command ldflags, opt='', libpath=$LIBPATH
  old_link_command ldflags, opt, libpath
end

def with_custom_link
  alias :old_link_command :link_command
  alias :link_command :nokogiri_link_command
  yield
ensure
  alias :link_command :old_link_command
end

with_custom_link do
  with_cppflags $INCFLAGS do
    have_func('xmlRelaxNGSetParserStructuredErrors')
    have_func('xmlRelaxNGSetParserStructuredErrors')
    have_func('xmlRelaxNGSetValidStructuredErrors')
    have_func('xmlSchemaSetValidStructuredErrors')
    have_func('xmlSchemaSetParserStructuredErrors')
  end
end

if ENV['CPUPROFILE']
  unless find_library('profiler', 'ProfilerEnable', *LIB_DIRS)
    abort "google performance tools are not installed"
  end
end

create_makefile('nokogiri/nokogiri')
# :startdoc:
