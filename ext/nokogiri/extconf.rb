ENV["ARCHFLAGS"] = "-arch #{`uname -p` =~ /powerpc/ ? 'ppc' : 'i386'}"

require 'mkmf'

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
PREFIX = Config::CONFIG['prefix']

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
  find_library('xml2', 'xmlParseDoc', "#{PREFIX}/lib")
  find_library('xslt', 'xsltParseStylesheetDoc', "#{PREFIX}/lib")
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
  unless find_header('libxml/xmlversion.h', "#{PREFIX}/include/libxml2")
    abort "need libxml"
  end
  unless find_header('libxslt/xslt.h', "#{PREFIX}/include")
    abort "need libxslt"
  end
end

unless find_executable("racc")
  abort "need racc, get the tarball from http://i.loveruby.net/archive/racc/racc-1.4.5-all.tar.gz" 
end

unless find_executable("frex")
  abort "need frex, sudo gem install aaronp-frex -s http://gems.github.com"   
end

create_makefile('nokogiri/native')
