require 'rubygems/package_task'
require 'rake/clean'

# home directory - used to find gumbo-parser/src by extconf.rb
ENV['RAKEHOME'] = File.dirname(File.expand_path(__FILE__))

# default to running tests
task 'default' => 'test'

task 'test' => 'compile' do
  ruby 'test-nokogumbo.rb'
end

# ensure gumbo-parser submodule is updated
DLEXT = RbConfig::CONFIG['DLEXT']
EXT = 'ext/nokogumboc'
file "#{EXT}/nokogumboc.#{DLEXT}" => ["#{EXT}/Makefile","#{EXT}/nokogumbo.c"] do
  Dir.chdir 'ext/nokogumboc' do
    sh 'make'
  end
end

file "#{EXT}/Makefile" => ['gumbo-parser/src', "#{EXT}/extconf.rb"] do
  Dir.chdir 'ext/nokogumboc' do
    ruby 'extconf.rb'
  end
end

task 'compile' => "#{EXT}/nokogumboc.#{DLEXT}"

file 'gumbo-parser/src' do
  sh 'git submodule init'
  sh 'git submodule update'
end

task 'pull' => 'gumbo-parser/src' do
  sh 'git submodule foreach git pull origin master'
end

# list of ext source files to be included in package, excluded from CLEAN
SOURCES = ['ext/nokogumboc/extconf.rb', 'ext/nokogumboc/nokogumbo.c']

# gem, package, and extension tasks
task 'gem' => 'test'
SPEC = Gem::Specification.new do |gem|
  gem.name = 'nokogumbo'
  gem.version = '1.4.10'
  gem.email = 'rubys@intertwingly.net'
  gem.homepage = 'https://github.com/rubys/nokogumbo/#readme'
  gem.summary = 'Nokogiri interface to the Gumbo HTML5 parser'
  gem.extensions = 'ext/nokogumboc/extconf.rb'
  gem.author = 'Sam Ruby'
  gem.add_dependency 'nokogiri'
  gem.license = 'Apache-2.0'
  gem.description = %q(
    Nokogumbo allows a Ruby program to invoke the Gumbo HTML5 parser and
    access the result as a Nokogiri parsed document.).strip.gsub(/\s+/, ' ')
  gem.files = SOURCES + FileList[
    'lib/nokogumbo.rb',
    'LICENSE.txt',
    'README.md',
    'gumbo-parser/src/*',
    'gumbo-parser/visualc/include/*',
    'test-nokogumbo.rb'
  ]
end

PKG = Gem::PackageTask.new(SPEC) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

# cleanup
CLEAN.include FileList.new('ext/nokogumboc/*')-SOURCES
CLOBBER.include FileList.new('pkg', 'Gemfile.lock')

# silence cleanup operations
Rake::Task[:clobber_package].clear
CLEAN.existing!
CLOBBER.existing!.uniq!
