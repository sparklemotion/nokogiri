ENV["ARCHFLAGS"] = "-arch #{`uname -p` =~ /powerpc/ ? 'ppc' : 'i386'}"

require 'mkmf'

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
LIBDIR = Config::CONFIG['libdir']
INCLUDEDIR = Config::CONFIG['includedir']

  use_macports = !(defined?(RUBY_ENGINE) && RUBY_ENGINE != 'ruby')

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
    '/usr/include/libxml2',
    '/usr/local/include/libxml2'
  ]

  [
    '/opt/local/include/libxml2',
    '/opt/local/include',
  ].each { |x| HEADER_DIRS.unshift(x) } if use_macports

  unless find_header('libxml/xmlversion.h', *HEADER_DIRS)
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
  find_library('xml2', 'xmlParseDoc',
               LIBDIR,
               '/opt/local/lib',
               '/usr/local/lib',
               '/usr/lib'
    )
  find_library('xslt', 'xsltParseStylesheetDoc',
               LIBDIR,
               '/opt/local/lib',
               '/usr/local/lib',
               '/usr/lib'
    )
  find_library('exslt', 'exsltFuncRegister',
               LIBDIR,
               '/opt/local/lib',
               '/usr/local/lib',
               '/usr/lib'
    )
end

create_makefile('nokogiri/native')
