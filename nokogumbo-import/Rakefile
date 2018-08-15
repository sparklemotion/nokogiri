require 'rubygems/package_task'
require 'rake/clean'
require 'rake/extensiontask'
require 'rake/testtask'

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "nokogumbo/version"

# default to running tests
task :default => :test

ext = Rake::ExtensionTask.new 'nokogumbo' do |ext|
  ext.lib_dir = 'lib/nokogumbo'
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
end

task :test => :compile

# list of ext source files to be included in package, excluded from CLEAN
SOURCES = ['ext/nokogumbo/extconf.rb', 'ext/nokogumbo/nokogumbo.c']

# gem, package, and extension tasks
task 'gem' => 'test'

SPEC = Gem::Specification.new do |gem|
  gem.name = 'nokogumbo'
  gem.version = Nokogumbo::VERSION
  gem.email = 'rubys@intertwingly.net'
  gem.homepage = 'https://github.com/rubys/nokogumbo/#readme'
  gem.summary = 'Nokogiri interface to the Gumbo HTML5 parser'
  gem.extensions = %w[ext/nokogumbo/extconf.rb]
  gem.author = 'Sam Ruby'
  gem.add_dependency 'nokogiri'
  gem.license = 'Apache-2.0'
  gem.description = %q(
    Nokogumbo allows a Ruby program to invoke the Gumbo HTML5 parser and
    access the result as a Nokogiri parsed document.).strip.gsub(/\s+/, ' ')
  gem.files = SOURCES + FileList[
    'lib/nokogumbo.rb',
    'lib/nokogumbo/version.rb',
    'LICENSE.txt',
    'README.md',
    'gumbo-parser/src/*.[hc]',
    'gumbo-parser/visualc/include/*.h',
  ]
end

PKG = Gem::PackageTask.new(SPEC) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

# cleanup
CLEAN.include FileList.new('ext/nokogumbo/*')-SOURCES
CLEAN.include File.join('lib/nokogumbo', ext.binary)
CLOBBER.include FileList.new('pkg', 'Gemfile.lock')

# silence cleanup operations
Rake::Task[:clobber_package].clear
CLEAN.existing!
CLOBBER.existing!.uniq!
