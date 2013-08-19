require 'rubygems/package_task'
require 'rake/clean'

task 'default' => 'test'

file 'gumbo-parser' do
  sh 'git clone https://github.com/google/gumbo-parser.git'
end

file 'work/extconf.rb' => 'gumbo-parser' do
  mkdir_p 'work'
  cp Dir['gumbo-parser/src/*'], 'work'
  cp Dir['ext/*'], 'work'
end

file 'work/Makefile' => 'work/extconf.rb' do
  Dir.chdir 'work' do 
    ruby 'extconf.rb'
  end
end

task 'test' => 'work/Makefile' do
  Dir.chdir 'work' do 
    sh 'make -s'
  end
  ruby 'test-nokogumbo.rb'
end

CLEAN.include 'pkg', 'gumbo-parser', 'work'

MANIFEST = FileList[*%w(
  work/*.rb  
  work/*.c  
  work/*.h  
  lib/nokogumbo.rb  
  LICENSE.txt
  Rakefile  
  README.md
)]

SPEC = Gem::Specification.new do |gem|
  gem.name = 'nokogumbo'
  gem.version = '0.3'
  gem.email = 'rubys@intertwingly.net'
  gem.homepage = 'https://github.com/rubys/nokogumbo/#readme'
  gem.summary = 'Nokogiri interface to the Gumbo HTML5 parser'
  gem.files = MANIFEST
  gem.extensions = 'work/extconf.rb'
  gem.author = 'Sam Ruby'
  gem.add_dependency 'nokogiri'
  gem.license = 'Apache 2.0'
  gem.description = %q(
    Nokogumbo allows a Ruby program to invoke the Gumbo HTML5 parser and
    access the result as a Nokogiri parsed document.).strip.gsub(/\s+/, ' ')
end

task 'gem' => 'test'
Gem::PackageTask.new(SPEC) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end
