ENV["ARCHFLAGS"] = "-arch #{`uname -p` =~ /powerpc/ ? 'ppc' : 'i386'}"

require 'mkmf'

find_library('xml2', 'xmlParseDoc')

unless find_header('libxml/xmlversion.h', '/usr/include/libxml2')
  puts "need libxml"
  exit 1
end

create_makefile('nokogiri/native')
