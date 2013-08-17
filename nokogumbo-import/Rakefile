require 'rubygems/package_task'
require 'rake/clean'

task 'default' => 'test'

file 'Makefile' => 'ext/extconf.rb' do
  Dir.chdir 'ext' do 
    ruby 'extconf.rb'
  end
end

task 'test' => 'Makefile' do
  Dir.chdir 'ext' do 
    sh 'make -s'
  end
  ruby 'test-nokogumbo.rb'
end

CLEAN.include('ext/*.o', 'ext/*.so', 'ext/*.log', 'ext/Makefile', 'pkg')

MANIFEST = %w(
  ext/extconf.rb  
  ext/nokogumbo.c  
  lib/nokogumbo.rb  
  Rakefile  
  README.md
)

SPEC = Gem::Specification.new do |gem|
  gem.name = 'nokogumbo'
  gem.version = '0.1'
  gem.email = 'rubys@intertwingly.net'
  gem.homepage = 'https://github.com/rubys/nokogumbo/tree/master/ruby#readme'
  gem.summary = 'Nokogiri interface to the Gumbo HTML5 parser'
  gem.files = MANIFEST
  gem.extensions = 'ext/extconf.rb'
  gem.author = 'Sam Ruby'
  gem.add_dependency 'nokogiri'
  gem.license = 'MIT'
  gem.description = %q(
    At the moment, this is a proof of concept, allowing a Ruby
    program to invoke the Gumbo HTML5 parser and access the result as a Nokogiri
    parsed document.).strip.gsub(/\s+/, ' ')
end

task 'gem' => 'test'
Gem::PackageTask.new(SPEC) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end
