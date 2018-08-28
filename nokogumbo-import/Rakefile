require 'rubygems/package_task'
require 'rake/clean'
require 'rake/extensiontask'
require 'rake/testtask'

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nokogumbo/version'

# default to running tests
task default: :test
task test: :compile
task gem: [:test, 'test:gumbo']

ext = Rake::ExtensionTask.new 'nokogumbo' do |e|
  e.lib_dir = 'lib/nokogumbo'
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/test_*.rb']
end

# list of ext source files to be included in package, excluded from CLEAN
SOURCES = Dir['ext/nokogumbo/*.{rb,c}']

desc 'Run the gumbo unit tests'
task 'test:gumbo' => 'gumbo-parser/googletest' do
  sh('make', '-C', 'gumbo-parser')
end

desc 'Start a console'
task console: :compile do
  sh('irb', '-Ilib', '-rnokogumbo')
end

SPEC = Gem::Specification.new do |gem|
  gem.name = 'nokogumbo'
  gem.version = Nokogumbo::VERSION
  gem.homepage = 'https://github.com/rubys/nokogumbo/#readme'
  gem.summary = 'Nokogiri interface to the Gumbo HTML5 parser'
  gem.extensions = %w[ext/nokogumbo/extconf.rb]
  gem.authors = ['Sam Ruby', 'Stephen Checkoway']
  gem.email = ['rubys@intertwingly.net', 's@pahtak.org']
  gem.add_dependency 'nokogiri'
  gem.license = 'Apache-2.0'
  gem.description = 'Nokogumbo allows a Ruby program to invoke the Gumbo ' \
    'HTML5 parser and access the result as a Nokogiri parsed document.'
  gem.files = SOURCES + FileList[
    'CHANGELOG.md',
    'LICENSE.txt',
    'README.md',
    'lib/**/*.rb',
    'gumbo-parser/src/*.[hc]',
    'gumbo-parser/visualc/include/*.h',
  ]
  gem.metadata = {
    'bug_tracker_uri' => 'https://github.com/rubys/nokogumbo/issues',
    'changelog_uri'   => 'https://github.com/rubys/nokogumbo/blob/master/CHANGELOG.md',
    'homepage_uri'    => gem.homepage,
    'source_code_uri' => 'https://github.com/rubys/nokogumbo'
  }
end

PKG = Gem::PackageTask.new(SPEC) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

# cleanup
CLEAN.include(FileList.new('ext/nokogumbo/*') - SOURCES)
CLEAN.include(File.join('lib/nokogumbo', ext.binary))
CLOBBER.include(FileList.new('pkg', 'Gemfile.lock'))

# silence cleanup operations
Rake::Task[:clobber_package].clear
CLEAN.existing!
CLOBBER.existing!.uniq!
