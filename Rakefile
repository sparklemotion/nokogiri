# -*- ruby -*-

require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'

windows = RUBY_PLATFORM =~ /(mswin|mingw)/i
java    = RUBY_PLATFORM =~ /java/

GENERATED_PARSER    = "lib/nokogiri/css/generated_parser.rb"
GENERATED_TOKENIZER = "lib/nokogiri/css/generated_tokenizer.rb"

# Make sure hoe-debugging is installed
Hoe.plugin :debugging

HOE = Hoe.spec 'nokogiri' do
  developer('Aaron Patterson', 'aaronp@rubyforge.org')
  developer('Mike Dalessio', 'mike.dalessio@gmail.com')
  self.readme_file   = ['README', ENV['HLANG'], 'rdoc'].compact.join('.')
  self.history_file  = ['CHANGELOG', ENV['HLANG'], 'rdoc'].compact.join('.')
  self.extra_rdoc_files  = FileList['*.rdoc']
  self.clean_globs = [
    'lib/nokogiri/*.{o,so,bundle,a,log,dll}',
    GENERATED_PARSER,
    GENERATED_TOKENIZER,
    'cross',
  ]

  %w{ racc rexical rake-compiler }.each do |dep|
    self.extra_dev_deps << dep
  end

  self.spec_extras = { :extensions => ["ext/nokogiri/extconf.rb"] }
end

unless java
  gem 'rake-compiler', '>= 0.4.1'
  require "rake/extensiontask"

  RET = Rake::ExtensionTask.new("nokogiri", HOE.spec) do |ext|
    ext.lib_dir = File.join(*['lib', 'nokogiri', ENV['FAT_DIR']].compact)

    ext.config_options << ENV['EXTOPTS']
    cross_dir = File.join(File.dirname(__FILE__), 'tmp', 'cross')
    ext.cross_compile   = true
    ext.cross_platform  = 'i386-mingw32'
    ext.cross_config_options <<
      "--with-iconv-dir=#{File.join(cross_dir, 'iconv')}"
    ext.cross_config_options <<
      "--with-xml2-dir=#{File.join(cross_dir, 'libxml2')}"
    ext.cross_config_options <<
      "--with-xslt-dir=#{File.join(cross_dir, 'libxslt')}"
  end

  file 'lib/nokogiri/nokogiri.rb' do
    File.open("lib/#{HOE.name}/#{HOE.name}.rb", 'wb') do |f|
      f.write <<-eoruby
require "#{HOE.name}/\#{RUBY_VERSION.sub(/\\.\\d+$/, '')}/#{HOE.name}"
      eoruby
    end
  end

  namespace :cross do
    task :file_list do
      HOE.spec.platform = 'x86-mswin32'
      HOE.spec.extensions = []
      HOE.spec.files += Dir["lib/#{HOE.name}/#{HOE.name}.rb"]
      HOE.spec.files += Dir["ext/nokogiri/*.dll"]
    end
  end

  CLOBBER.include("lib/nokogiri/nokogiri.{so,dylib,rb,bundle}")
  CLOBBER.include("lib/nokogiri/1.{8,9}")
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

  desc "Build a gem targetted for JRuby"
  task :jruby => ['gem:jruby:spec'] do
    system "gem build nokogiri.gemspec"
    FileUtils.mkdir_p "pkg"
    FileUtils.mv Dir.glob("nokogiri*-java.gem"), "pkg"
  end

  namespace :jruby do
    task :spec => [GENERATED_PARSER, GENERATED_TOKENIZER] do
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
    sh "#{racc} -l -o #{t.name} #{t.prerequisites.first}"
  rescue
    abort "need racc, sudo gem install racc"
  end
end

file GENERATED_TOKENIZER => "lib/nokogiri/css/tokenizer.rex" do |t|
  begin
    sh "rex --independent -o #{t.name} #{t.prerequisites.first}"
  rescue
    abort "need rexical, sudo gem install rexical"
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
      url = "ftp://ftp.xmlsoft.org/libxml2/win32/#{lib}.zip"
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
    Rake::Task[:cross].prerequisites << "lib/nokogiri/nokogiri.rb"
    Rake::Task[:cross].prerequisites << "cross:file_list"
  end
end

require 'tasks/test'

desc "set environment variables to build and/or test with debug options"
task :debug do
  ENV['NOKOGIRI_DEBUG'] = "true"
  ENV['CFLAGS'] ||= ""
  ENV['CFLAGS'] += " -DDEBUG"
end

# required_ruby_version

# Only do this on unix, since we can't build on windows
unless windows || java || ENV['NOKOGIRI_FFI']
  [:compile, :check_manifest].each do |task_name|
    Rake::Task[task_name].prerequisites << GENERATED_PARSER
    Rake::Task[task_name].prerequisites << GENERATED_TOKENIZER
  end

  Rake::Task[:test].prerequisites << :compile
  if Hoe.plugins.include?(:debugging)
    ['valgrind', 'valgrind:mem', 'valgrind:mem0'].each do |task_name|
      Rake::Task["test:#{task_name}"].prerequisites << :compile
    end
  end
else
  [:test, :check_manifest].each do |task_name|
    if Rake::Task[task_name]
      Rake::Task[task_name].prerequisites << GENERATED_PARSER
      Rake::Task[task_name].prerequisites << GENERATED_TOKENIZER
    end
  end
end

namespace :install do
  desc "Install rex and racc for development"
  task :deps => %w(rexical racc)

  task :racc do |t|
    sh "sudo gem install racc"
  end

  task :rexical do
    sh "sudo gem install rexical"
  end
end

# vim: syntax=Ruby
