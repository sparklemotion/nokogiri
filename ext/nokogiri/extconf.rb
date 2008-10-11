ENV["ARCHFLAGS"] = "-arch #{`uname -p` =~ /powerpc/ ? 'ppc' : 'i386'}"

require 'mkmf'

if Config::CONFIG['target_os'] == 'mingw32'
  $CFLAGS << " -DXP_WIN -DXP_WIN32"
else
  $CFLAGS << " -g -DXP_UNIX"
end

$CFLAGS << " -O3 -Wall -Wextra -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"

find_library('xml2', 'xmlParseDoc')
find_library('xslt', 'xsltParseStylesheetDoc')

unless find_header('libxml/xmlversion.h', '/usr/include/libxml2')
  abort "need libxml"
end

if Config::CONFIG['target_os'] == 'mingw32'
  unless find_header('libxslt/xslt.h', ENV['HOME'] + '/cross/include')
    abort "need libxslt"
  end
else
  unless find_header('libxslt/xslt.h', '/usr/include')
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
