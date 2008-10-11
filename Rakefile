# -*- ruby -*-

require 'rubygems'
require 'hoe'

kind = Config::CONFIG['DLEXT']

LIB_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH << LIB_DIR

GENERATED_PARSER = "lib/nokogiri/css/generated_parser.rb"
GENERATED_TOKENIZER = "lib/nokogiri/css/generated_tokenizer.rb"

EXT = "ext/nokogiri/native.#{kind}"

require 'nokogiri/version'

HOE = Hoe.new('nokogiri', Nokogiri::VERSION) do |p|
  p.developer('Aaron Patterson', 'aaronp@rubyforge.org')
  p.clean_globs = [
    'ext/nokogiri/Makefile',
    'ext/nokogiri/*.{o,so,bundle,a,log}',
    'ext/nokogiri/conftest.dSYM',
    GENERATED_PARSER,
    GENERATED_TOKENIZER,
  ]
  p.spec_extras = { :extensions => ["Rakefile"] }
  p.extra_deps = ["rake"]
end

namespace :gem do
  task :spec do
    File.open("#{HOE.name}.gemspec", 'w') do |f|
      HOE.spec.version = "#{HOE.version}.#{Time.now.strftime("%Y%m%d%H%M%S")}"
      f.write(HOE.spec.to_ruby)
    end
  end
end

desc "Run code-coverage analysis"
task :coverage do
  rm_rf "coverage"
  sh "rcov -x Library -I lib:test #{Dir[*HOE.test_globs].join(' ')}"
end

file GENERATED_PARSER => "lib/nokogiri/css/parser.y" do |t|
  sh "racc -o #{t.name} #{t.prerequisites.first}"
end

file GENERATED_TOKENIZER => "lib/nokogiri/css/tokenizer.rex" do |t|
  sh "frex -i --independent -o #{t.name} #{t.prerequisites.first}"
end

task 'ext/nokogiri/Makefile' do
  Dir.chdir('ext/nokogiri') do
    ruby 'extconf.rb'
  end
end

task EXT => 'ext/nokogiri/Makefile' do
  Dir.chdir('ext/nokogiri') do
    sh 'make'
  end
end

task :build => [EXT, GENERATED_PARSER, GENERATED_TOKENIZER]

Rake::Task[:test].prerequisites << :build
Rake::Task[:check_manifest].prerequisites << GENERATED_PARSER
Rake::Task[:check_manifest].prerequisites << GENERATED_TOKENIZER

# vim: syntax=Ruby
