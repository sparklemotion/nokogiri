ENV["ARCHFLAGS"] = "-arch #{`uname -p` =~ /powerpc/ ? 'ppc' : 'i386'}"

require 'mkmf'

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
LIBDIR = Config::CONFIG['libdir']
INCLUDEDIR = Config::CONFIG['includedir']

$CFLAGS << " #{ENV["CFLAGS"]}"
if Config::CONFIG['target_os'] == 'mingw32'
  $CFLAGS << " -DXP_WIN -DXP_WIN32"
else
  $CFLAGS << " -g -DXP_UNIX"
end

$CFLAGS << " -O3 -Wall -Wextra -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"

if Config::CONFIG['target_os'] == 'mingw32'
  find_library('xml2', 'xmlParseDoc',
               File.join(ROOT, 'cross', 'libxml2-2.7.2.win32', 'bin'))
  find_library('xslt', 'xsltParseStylesheetDoc',
               File.join(ROOT, 'cross', 'libxslt-1.1.24.win32', 'bin'))
else
  find_library('xml2', 'xmlParseDoc', LIBDIR)
  find_library('xslt', 'xsltParseStylesheetDoc', LIBDIR)
end


if Config::CONFIG['target_os'] == 'mingw32'
  header = File.join(ROOT, 'cross', 'libxml2-2.7.2.win32', 'include')
  unless find_header('libxml/xmlversion.h', header)
    abort "need libxml"
  end

  header = File.join(ROOT, 'cross', 'libxslt-1.1.24.win32', 'include')
  unless find_header('libxslt/libxslt.h', header)
    abort "need libxslt"
  end

  header = File.join(ROOT, 'cross', 'iconv-1.9.2.win32', 'include')
  unless find_header('iconv.h', header)
    abort "need iconv"
  end
else
  unless find_header('libxml/xmlversion.h',
                     File.join(INCLUDEDIR, "libxml2"),
                     '/opt/local/include/libxml2',
                     '/usr/local/include/libxml2',
                     '/usr/include/libxml2'
                    )
    abort "need libxml"
  end
  unless find_header('libxslt/xslt.h',
                     INCLUDEDIR,
                     '/opt/local/include',
                     '/usr/local/include',
                     '/usr/include'
                    )
    abort "need libxslt"
  end

  version = try_constant('LIBXML_VERSION', 'libxml/xmlversion.h')
end

create_makefile('nokogiri/native')
