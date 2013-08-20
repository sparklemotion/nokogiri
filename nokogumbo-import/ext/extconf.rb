require 'mkmf'
$CFLAGS = " -std=c99"
pkg_config('libxml-2.0')
nokogiri_lib = Gem.find_files('nokogiri').first
nokogiri_ext = nokogiri_lib.sub(%r(lib/nokogiri$), 'ext/nokogiri')
find_header('nokogiri.h', nokogiri_ext)
create_makefile('nokogumboc')
