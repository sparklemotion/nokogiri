# -*- ruby -*-

require 'rubygems'
require 'hoe'

LIB_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
GENERATED_INTERFACE = File.join(LIB_DIR, 'nokogiri', 'generated_interface.rb')

$LOAD_PATH << LIB_DIR

require 'nokogiri/version'

Hoe.new('nokogiri', Nokogiri::VERSION) do |p|
  p.developer('Aaron Patterson', 'aaronp@rubyforge.org')
  p.clean_globs = [GENERATED_INTERFACE]
end

file GENERATED_INTERFACE => 'idl/dom.idl' do |t|
  sh "omfg --prefix W3C::Org -o #{t.name} #{t.prerequisites.first}"
end

Rake::Task[:test].prerequisites << GENERATED_INTERFACE
Rake::Task[:check_manifest].prerequisites << GENERATED_INTERFACE


# vim: syntax=Ruby
