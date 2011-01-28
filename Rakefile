# -*- ruby -*-

require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'

windows = RUBY_PLATFORM =~ /(mswin|mingw)/i
java    = RUBY_PLATFORM =~ /java/

GENERATED_PARSER    = "lib/nokogiri/css/parser.rb"
GENERATED_TOKENIZER = "lib/nokogiri/css/tokenizer.rb"
CROSS_DIR           = File.join(File.dirname(__FILE__), 'tmp', 'cross')

# Make sure hoe-debugging is installed
Hoe.plugin :debugging
Hoe.plugin :git
Hoe.plugin :gemspec

HOE = Hoe.spec 'nokogiri' do
  developer('Aaron Patterson', 'aaronp@rubyforge.org')
  developer('Mike Dalessio', 'mike.dalessio@gmail.com')
  self.readme_file   = ['README', ENV['HLANG'], 'rdoc'].compact.join('.')
  self.history_file  = ['CHANGELOG', ENV['HLANG'], 'rdoc'].compact.join('.')
  self.extra_rdoc_files  = FileList['*.rdoc','ext/nokogiri/*.c']
  self.clean_globs = [
    'lib/nokogiri/*.{o,so,bundle,a,log,dll}',
    'lib/nokogiri/nokogiri.rb',
    'lib/nokogiri/1.{8,9}',
    GENERATED_PARSER,
    GENERATED_TOKENIZER,
    'cross',
  ]

  %w{ racc rexical rake-compiler }.each do |dep|
    extra_dev_deps << [dep, '>= 0']
  end
  extra_dev_deps << ["minitest", ">= 1.6.0"]

  if java
    self.spec_extras = { :platform => 'java' }
  else
    self.spec_extras = { :extensions => ["ext/nokogiri/extconf.rb"] }
  end

  self.testlib = :minitest
end

Hoe.add_include_dirs '.'

task :ws_docs do
  title = "#{HOE.name}-#{HOE.version} Documentation"

  options = []
  options << "--main=#{HOE.readme_file}"
  options << '--format=activerecord'
  options << '--threads=1'
  options << "--title=#{title.inspect}"

  options += HOE.spec.require_paths
  options += HOE.spec.extra_rdoc_files
  require 'rdoc/rdoc'
  ENV['RAILS_ROOT'] ||= File.expand_path(File.join('..', 'nokogiri_ws'))
  RDoc::RDoc.new.document options
end

gem 'rake-compiler', '>= 0.4.1'
if java
  require "rake/javaextensiontask"
  Rake::JavaExtensionTask.new("nokogiri", HOE.spec) do |ext|
    jruby_home = RbConfig::CONFIG['prefix']
    ext.ext_dir = 'ext/java'
    ext.lib_dir = 'lib/nokogiri'
    ext.classpath = (["#{jruby_home}/lib/jruby.jar"] + FileList['lib/*.jar'].map { |x| File.expand_path x }).join ':'
  end
  path = "pkg/#{HOE.spec.name}-#{HOE.spec.version}"
  task path => :compile do
    cp 'lib/nokogiri/nokogiri.jar', File.join(path, 'lib')
    HOE.spec.files += ['lib/nokogiri/nokogiri.jar']
  end
else
  require "rake/extensiontask"
  Rake::ExtensionTask.new("nokogiri", HOE.spec) do |ext|
    ext.lib_dir = File.join(*['lib', 'nokogiri', ENV['FAT_DIR']].compact)

    ext.config_options << ENV['EXTOPTS']
    ext.cross_compile   = true
    ext.cross_platform  = 'i386-mingw32'
    # ext.cross_platform  = 'i386-mswin32'
    ext.cross_config_options <<
    "--with-xml2-include=#{File.join(CROSS_DIR, 'include', 'libxml2')}"
    ext.cross_config_options <<
    "--with-xml2-lib=#{File.join(CROSS_DIR, 'lib')}"
    ext.cross_config_options << "--with-iconv-dir=#{CROSS_DIR}"
    ext.cross_config_options << "--with-xslt-dir=#{CROSS_DIR}"
    ext.cross_config_options << "--with-zlib-dir=#{CROSS_DIR}"
  end
end

task 'gem:spec' => [ GENERATED_PARSER, GENERATED_TOKENIZER ]

file GENERATED_PARSER => "lib/nokogiri/css/parser.y" do |t|
  racc = RbConfig::CONFIG['target_os'] =~ /mswin32/ ? '' : `which racc`.strip
  racc = "#{::RbConfig::CONFIG['bindir']}/racc" if racc.empty?
  sh "#{racc} -l -o #{t.name} #{t.prerequisites.first}"
end

file GENERATED_TOKENIZER => "lib/nokogiri/css/tokenizer.rex" do |t|
  sh "rex --independent -o #{t.name} #{t.prerequisites.first}"
end

require 'tasks/test'
begin
  require 'tasks/cross_compile'
rescue RuntimeError => e
  warn "WARNING: Could not perform some cross-compiling: #{e}"
end

desc "set environment variables to build and/or test with debug options"
task :debug do
  ENV['NOKOGIRI_DEBUG'] = "true"
  ENV['CFLAGS'] ||= ""
  ENV['CFLAGS'] += " -DDEBUG"
end

# required_ruby_version

# Only do this on unix, since we can't build on windows
unless windows
  [:compile, :check_manifest].each do |task_name|
    Rake::Task[task_name].prerequisites << GENERATED_PARSER
    Rake::Task[task_name].prerequisites << GENERATED_TOKENIZER
  end

  Rake::Task[:test].prerequisites << :compile
  Rake::Task[:test].prerequisites << :check_extra_deps unless java
  if Hoe.plugins.include?(:debugging)
    ['valgrind', 'valgrind:mem', 'valgrind:mem0'].each do |task_name|
      Rake::Task["test:#{task_name}"].prerequisites << :compile
    end
  end
end

namespace :rip do
  task :install => [GENERATED_TOKENIZER, GENERATED_PARSER]
end

# vim: syntax=Ruby
