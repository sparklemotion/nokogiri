ENV["ARCHFLAGS"] = "-arch #{`uname -p` =~ /powerpc/ ? 'ppc' : 'i386'}"

require 'mkmf'

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
LIBDIR = Config::CONFIG['libdir']
INCLUDEDIR = Config::CONFIG['includedir']

use_macports = !(defined?(RUBY_ENGINE) && RUBY_ENGINE != 'ruby')

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'macruby'
  $LIBRUBYARG_STATIC.gsub!(/-static/, '')
end

$CFLAGS << " #{ENV["CFLAGS"]}"
if Config::CONFIG['target_os'] == 'mingw32'
  $CFLAGS << " -DXP_WIN -DXP_WIN32"
else
  $CFLAGS << " -g -DXP_UNIX"
end

$LIBPATH << "/opt/local/lib" if use_macports

$CFLAGS << " -O3 -Wall -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"

if Config::CONFIG['target_os'] == 'mingw32'
  header = File.join(ROOT, 'cross', 'libxml2-2.7.2.win32', 'include')
  unless find_header('libxml/xmlversion.h', header)
    abort "need libxml"
  end

  header = File.join(ROOT, 'cross', 'libxslt-1.1.24.win32', 'include')
  unless find_header('libxslt/libxslt.h', header)
    abort "need libxslt"
  end
  unless find_header('libexslt/libexslt.h', header)
    abort "need libexslt"
  end

  header = File.join(ROOT, 'cross', 'iconv-1.9.2.win32', 'include')
  unless find_header('iconv.h', header)
    abort "need iconv"
  end
else
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

  [
    '/opt/local/include/libxml2',
    '/opt/local/include',
  ].each { |x| HEADER_DIRS.unshift(x) } if use_macports

  xml2_dirs = dir_config('xml2')
  unless [nil, nil] == xml2_dirs
    HEADER_DIRS.unshift xml2_dirs.first
    LIB_DIRS.unshift xml2_dirs[1]
  end

  xslt_dirs = dir_config('xslt')
  unless [nil, nil] == xslt_dirs
    HEADER_DIRS.unshift xslt_dirs.first
    LIB_DIRS.unshift xslt_dirs[1]
  end

  unless find_header('libxml/parser.h', *HEADER_DIRS)
    abort "need libxml"
  end

  unless find_header('libxslt/xslt.h', *HEADER_DIRS)
    abort "need libxslt"
  end
  unless find_header('libexslt/exslt.h', *HEADER_DIRS)
    abort "need libxslt"
  end
end

if Config::CONFIG['target_os'] == 'mingw32'
  find_library('xml2', 'xmlParseDoc',
               File.join(ROOT, 'cross', 'libxml2-2.7.2.win32', 'bin'))
  find_library('xslt', 'xsltParseStylesheetDoc',
               File.join(ROOT, 'cross', 'libxslt-1.1.24.win32', 'bin'))
  find_library('exslt', 'exsltFuncRegister',
               File.join(ROOT, 'cross', 'libxslt-1.1.24.win32', 'bin'))
else
  unless find_library('xml2', 'xmlParseDoc', *LIB_DIRS)
    abort "need libxml2"
  end

  unless find_library('xslt', 'xsltParseStylesheetDoc', *LIB_DIRS)
    abort "need libxslt"
  end

  unless find_library('exslt', 'exsltFuncRegister', *LIB_DIRS)
    abort "need libxslt"
  end
end

create_makefile('nokogiri/native')
