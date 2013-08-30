require 'mkmf'
$CFLAGS = " -std=c99"

# libxml2 libraries from http://www.xmlsoft.org/
pkg_config('libxml-2.0')

# nokogiri configuration from gem install
nokogiri_lib = Gem.find_files('nokogiri').
  sort_by {|name| name[/nokogiri-([\d.]+)/,1].split('.').map(&:to_i)}.last
gem 'nokogiri' unless nokogiri_lib
nokogiri_ext = nokogiri_lib.sub(%r(lib/nokogiri(.rb)?$), 'ext/nokogiri')

# if that doesn't work, try workarounds found in Nokogiri's extconf
unless find_header('nokogiri.h', nokogiri_ext)
  require "#{nokogiri_ext}/extconf.rb"
  throw 'nokogiri.h not found' unless find_header('nokogiri.h', nokogiri_ext)
end

# add in gumbo-parser source from github if not already installed
unless have_library('gumbo', 'gumbo_parse') or File.exist? 'work/gumbo.h'
  require 'fileutils'
  rakehome = ENV['RAKEHOME'] || File.expand_path('../..')
  FileUtils.cp Dir["#{rakehome}/gumbo-parser/src/*"],
    "#{rakehome}/ext/nokogumboc"
end

create_makefile('nokogumboc')
