ENV["ARCHFLAGS"] = "-arch #{`uname -p` =~ /powerpc/ ? 'ppc' : 'i386'}"

require 'mkmf'

$CFLAGS << " -g -DXP_UNIX"
$CFLAGS << " -O3 -Wall -Wextra -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"

find_library('xml2', 'xmlParseDoc')
find_library('xslt', 'xsltParseStylesheetDoc')

unless find_header('libxml/xmlversion.h', '/usr/include/libxml2') &&
    find_header('libxslt/xslt.h', '/usr/include')
  abort "need libxml"
end

unless find_executable("racc")
  abort "need racc, get the tarball from http://i.loveruby.net/archive/racc/racc-1.4.5-all.tar.gz" 
end

unless find_executable("frex")
  abort "need frex, sudo gem install aaronp-frex -s http://gems.github.com"   
end

create_makefile('nokogiri/native')
