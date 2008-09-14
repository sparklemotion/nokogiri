ENV["ARCHFLAGS"] = "-arch #{`uname -p` =~ /powerpc/ ? 'ppc' : 'i386'}"

require 'mkmf'

$CFLAGS << " -g -DXP_UNIX"
$CFLAGS << " -O3 -Wall -Wextra -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"

find_library('xml2', 'xmlParseDoc')
find_library('xslt', 'xsltParseStylesheetDoc')

unless find_header('libxml/xmlversion.h', '/usr/include/libxml2')
  puts "need libxml"
  exit 1
end
unless find_header('libxslt/xslt.h', '/usr/include')
  puts "need libxml"
  exit 1
end

create_makefile('nokogiri/native')
