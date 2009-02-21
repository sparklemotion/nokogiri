ENV["ARCHFLAGS"] = "-arch #{`uname -p` =~ /powerpc/ ? 'ppc' : 'i386'}"

require 'mkmf'

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
LIBDIR = Config::CONFIG['libdir']
INCLUDEDIR = Config::CONFIG['includedir']

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'macruby'
  $LIBRUBYARG_STATIC.gsub!(/-static/, '')
end

$CFLAGS << " #{ENV["CFLAGS"]}"
if Config::CONFIG['target_os'] == 'mingw32'
  $CFLAGS << " -DXP_WIN -DXP_WIN32"
else
  $CFLAGS << " -g -DXP_UNIX"
end

$CFLAGS << " -O3 -Wall -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"

HEADER_DIRS = [
  File.join(INCLUDEDIR, "libxml2"),
  INCLUDEDIR,
  '/usr/local/include/libxml2',
  '/usr/include/libxml2',
]

LIB_DIRS = [
  LIBDIR,
  '/opt/local/lib',
  '/usr/local/lib',
  '/usr/lib'
]

if Config::CONFIG['target_os'] == 'mingw32'
  header = File.join(ROOT, 'cross', 'iconv-1.9.2.win32', 'include')
  unless find_header('iconv.h', header)
    abort "need iconv"
  end
end

xml2_dirs = dir_config('xml2', '/opt/local/include/libxml2', '/opt/local/lib')
unless [nil, nil] == xml2_dirs
  HEADER_DIRS.unshift xml2_dirs.first
  LIB_DIRS.unshift xml2_dirs[1]
end

xslt_dirs = dir_config('xslt', '/opt/local/include/', '/opt/local/lib')
unless [nil, nil] == xslt_dirs
  HEADER_DIRS.unshift xslt_dirs.first
  LIB_DIRS.unshift xslt_dirs[1]
end

unless find_header('libxml/parser.h', *HEADER_DIRS)
  abort "libxml2 is missing.  try 'port install libxml2' or 'yum install libxml2'"
end

unless find_header('libxslt/xslt.h', *HEADER_DIRS)
  abort "libxslt is missing.  try 'port install libxslt' or 'yum install libxslt'"
end
unless find_header('libexslt/exslt.h', *HEADER_DIRS)
  abort "libxslt is missing.  try 'port install libxslt' or 'yum install libxslt'"
end

unless find_library('xml2', 'xmlParseDoc', *LIB_DIRS)
  abort "libxml2 is missing.  try 'port install libxml2' or 'yum install libxml2'"
end

unless find_library('xslt', 'xsltParseStylesheetDoc', *LIB_DIRS)
  abort "libxslt is missing.  try 'port install libxslt' or 'yum install libxslt'"
end

unless find_library('exslt', 'exsltFuncRegister', *LIB_DIRS)
  abort "libxslt is missing.  try 'port install libxslt' or 'yum install libxslt'"
end

create_makefile('nokogiri/native')
