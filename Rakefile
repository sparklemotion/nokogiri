# -*- ruby -*-

require 'rubygems'
require 'rake'
require 'hoe'

LIB_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH << LIB_DIR

windows = RUBY_PLATFORM =~ /mswin/i ? true : false
java = RUBY_PLATFORM =~ /java/ ? true : false

GENERATED_PARSER    = "lib/nokogiri/css/generated_parser.rb"
GENERATED_TOKENIZER = "lib/nokogiri/css/generated_tokenizer.rb"

require 'nokogiri/version'

HOE = Hoe.new('nokogiri', Nokogiri::VERSION) do |p|
  p.developer('Aaron Patterson', 'aaronp@rubyforge.org')
  p.developer('Mike Dalessio', 'mike.dalessio@gmail.com')
  p.readme_file   = ['README', ENV['HLANG'], 'rdoc'].compact.join('.')
  p.history_file  = ['CHANGELOG', ENV['HLANG'], 'rdoc'].compact.join('.')
  p.extra_rdoc_files  = FileList['*.rdoc']
  p.clean_globs = [
    'ext/nokogiri/Makefile',
    'ext/nokogiri/*.{o,so,bundle,a,log,dll}',
    'ext/nokogiri/conftest.dSYM',
    GENERATED_PARSER,
    GENERATED_TOKENIZER,
    'cross',
  ]

  p.extra_dev_deps  << "racc"
  p.extra_dev_deps  << "tenderlove-frex"
  p.extra_dev_deps  << "rake-compiler"

  p.spec_extras = { :extensions => ["ext/nokogiri/extconf.rb"] }
end

unless java

  gem 'rake-compiler', '>= 0.4.1'
  require "rake/extensiontask"

  Rake::ExtensionTask.new("nokogiri", HOE.spec) do |ext|
    ext.lib_dir                         = "ext/nokogiri"
    ext.gem_spec.required_ruby_version  = "~> #{RUBY_VERSION.sub(/\.\d+$/, '.0')}"
    ext.config_options << ENV['EXTOPTS']
    cross_dir = File.join(File.dirname(__FILE__), 'tmp', 'cross')
    ext.cross_compile   = true
    ext.cross_platform  = 'i386-mswin32'
    ext.cross_config_options <<
      "--with-iconv-dir=#{File.join(cross_dir, 'iconv')}"
    ext.cross_config_options <<
      "--with-xml2-dir=#{File.join(cross_dir, 'libxml2')}"
    ext.cross_config_options <<
      "--with-xslt-dir=#{File.join(cross_dir, 'libxslt')}"
  end

end

namespace :gem do
  namespace :dev do
    task :spec do
      File.open("#{HOE.name}.gemspec", 'w') do |f|
        HOE.spec.version = "#{HOE.version}.#{Time.now.strftime("%Y%m%d%H%M%S")}"
        f.write(HOE.spec.to_ruby)
      end
    end
  end

  namespace :jruby do
    task :spec => ['build'] do
      File.open("#{HOE.name}.gemspec", 'w') do |f|
        HOE.spec.platform = 'java'
        HOE.spec.files << GENERATED_PARSER
        HOE.spec.files << GENERATED_TOKENIZER
        HOE.spec.extensions = []
        f.write(HOE.spec.to_ruby)
      end
    end
  end

  task :spec => ['gem:dev:spec']
end

file GENERATED_PARSER => "lib/nokogiri/css/parser.y" do |t|
  begin
    racc = `which racc`.strip
    racc = "#{::Config::CONFIG['bindir']}/racc" if racc.empty?
    sh "#{racc} -o #{t.name} #{t.prerequisites.first}"
  rescue
    abort "need racc, sudo gem install racc"
  end
end

file GENERATED_TOKENIZER => "lib/nokogiri/css/tokenizer.rex" do |t|
  begin
    sh "frex --independent -o #{t.name} #{t.prerequisites.first}"
  rescue
    abort "need frex, sudo gem install tenderlove-frex -s http://gems.github.com"
  end
end

libs = %w{
  iconv-1.9.2.win32
  zlib-1.2.3.win32
  libxml2-2.7.3.win32
  libxslt-1.1.24.win32
}

libs.each do |lib|
  file "tmp/stash/#{lib}.zip" do |t|
    puts "downloading #{lib}"
    FileUtils.mkdir_p('tmp/stash')
    Dir.chdir('tmp/stash') do
      url = "http://www.zlatkovic.com/pub/libxml/#{lib}.zip"
      system("wget #{url} || curl -O #{url}")
    end
  end
  file "tmp/cross/#{lib.split('-').first}" => ["tmp/stash/#{lib}.zip"] do |t|
    puts "unzipping #{lib}.zip"
    FileUtils.mkdir_p('tmp/cross')
    Dir.chdir('tmp/cross') do
      sh "unzip ../stash/#{lib}.zip"
      sh "cp #{lib}/bin/* #{lib}/lib" # put DLL in lib, so dirconfig works
      sh "cp #{lib}/bin/*.dll ../../ext/nokogiri/"
      sh "mv #{lib} #{lib.split('-').first}"
      sh "touch #{lib.split('-').first}"
    end
  end
  if Rake::Task.task_defined?(:cross)
    Rake::Task[:cross].prerequisites << "tmp/cross/#{lib.split('-').first}"
  end
end

require 'tasks/test'

desc "set environment variables to build and/or test with debug options"
task :debug do
  ENV['NOKOGIRI_DEBUG'] = "true"
  ENV['CFLAGS'] ||= ""
  ENV['CFLAGS'] += " -DDEBUG"
end

if Rake::Task.task_defined?(:cross)
  task :add_dll_to_manifest do
    HOE.spec.files += Dir['ext/nokogiri/**.{dll,so}']
  end

  Rake::Task[:cross].prerequisites << :add_dll_to_manifest
end

# required_ruby_version

# Only do this on unix, since we can't build on windows
unless windows || java
  [:compile, :check_manifest].each do |task_name|
    Rake::Task[task_name].prerequisites << GENERATED_PARSER
    Rake::Task[task_name].prerequisites << GENERATED_TOKENIZER
  end

  Rake::Task[:test].prerequisites << :compile
  ['valgrind', 'valgrind_mem', 'valgrind_mem0', 'coverage'].each do |task_name|
    Rake::Task["test:#{task_name}"].prerequisites << :compile
  end
end

namespace :install do
  desc "Install frex and racc for development"
  task :deps => %w(frex racc)

  task :racc do |t|
    sh "sudo gem install racc"
  end

  task :frex do
    sh "sudo gem install tenderlove-frex -s http://gems.github.com"
  end
end

namespace :libxml do
  desc "What version of LibXML are we building against?"
  task :version => :compile do
    sh "#{RUBY} -Ilib:ext -rnokogiri -e 'puts Nokogiri::LIBXML_VERSION'"
  end
end

require 'tasks/ffi'

# vim: syntax=Ruby
