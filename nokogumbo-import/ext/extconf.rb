require 'mkmf'
$CFLAGS = " -std=c99"

# libxml2 libraries from http://www.xmlsoft.org/
pkg_config('libxml-2.0')

# nokogiri headers from gem install
nokogiri_lib = Gem.find_files('nokogiri').first or gem 'nokogiri'
nokogiri_ext = nokogiri_lib.sub(%r(lib/nokogiri$), 'ext/nokogiri')
find_header('nokogiri.h', nokogiri_ext)

# add in gumbo-parser source from github if not already installed
unless have_library('gumbo', 'gumbo_parse') or File.exist? 'work/gumbo.h'
  require 'fileutils'
  FileUtils.cp Dir['../gumbo-parser/src/*'], '.'
end

create_makefile('nokogumboc')
