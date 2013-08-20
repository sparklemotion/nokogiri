require 'rubygems/package_task'
require 'rake/clean'

task 'default' => 'test'

file 'gumbo-parser' do
  sh 'git clone https://github.com/google/gumbo-parser.git'
end

file 'work/extconf.rb' => ['ext/extconf.rb', 'gumbo-parser'] do
  mkdir_p 'work'
  rm_f 'work/Makefile'
  cp Dir['gumbo-parser/src/*'], 'work', :preserve => true
  cp Dir['ext/*'], 'work'
end

file 'work/Makefile' => 'work/extconf.rb' do
  Dir.chdir 'work' do 
    ruby 'extconf.rb'
  end
end

file 'work/nokogumbo.c' => 'ext/nokogumbo.c' do
  cp 'ext/nokogumbo.c', 'work/nokogumbo.c'
end

task 'compile' => ['work/Makefile', 'work/nokogumbo.c'] do
  Dir.chdir 'work' do 
    sh 'make -s'
  end
end

task 'test' => 'compile' do
  ruby 'test-nokogumbo.rb'
end

CLEAN.include 'pkg', 'gumbo-parser', 'work'

SPEC = Gem::Specification.new do |gem|
  gem.name = 'nokogumbo'
  gem.version = '0.4'
  gem.email = 'rubys@intertwingly.net'
  gem.homepage = 'https://github.com/rubys/nokogumbo/#readme'
  gem.summary = 'Nokogiri interface to the Gumbo HTML5 parser'
  gem.extensions = 'work/extconf.rb'
  gem.author = 'Sam Ruby'
  gem.add_dependency 'nokogiri'
  gem.license = 'Apache 2.0'
  gem.description = %q(
    Nokogumbo allows a Ruby program to invoke the Gumbo HTML5 parser and
    access the result as a Nokogiri parsed document.).strip.gsub(/\s+/, ' ')
  gem.files = FileList[
    'lib/nokogumbo.rb',
    'LICENSE.txt',
    'Rakefile',
    'README.md'
  ]
end

task 'package_workfiles' => 'work/extconf.rb' do
  PKG.package_files += FileList['work/*.rb', 'work/*.c', 'work/*.h']
end

task 'gem' => ['test', 'package_workfiles']
PKG = Gem::PackageTask.new(SPEC) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end
