# -*- ruby -*-

require 'rubygems'
require 'rake'
require 'hoe'

LIB_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH << LIB_DIR

windows = RUBY_PLATFORM =~ /(mswin|mingw)/i ? true : false
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
    'lib/nokogiri/*.{o,so,bundle,a,log,dll}',
    GENERATED_PARSER,
    GENERATED_TOKENIZER,
    'cross',
  ]

  p.extra_dev_deps  << "racc"
  p.extra_dev_deps  << "rexical"
  p.extra_dev_deps  << "rake-compiler"

  p.spec_extras = { :extensions => ["ext/nokogiri/extconf.rb"] }
end

unless java

  gem 'rake-compiler', '>= 0.4.1'
  require "rake/extensiontask"

  RET = Rake::ExtensionTask.new("nokogiri", HOE.spec) do |ext|
    ext.lib_dir = File.join(*['lib', 'nokogiri', ENV['FAT_DIR']].compact)

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

  ###
  # To build the windows fat binary, do:
  #
  #   rake fat_binary native gem
  #
  # I keep my ruby in multiruby, so my command is like this:
  #
  #   RAKE19=~/.multiruby/install/1.9.1-p129/bin/rake \
  #     rake fat_binary native gem
  task 'fat_binary' do
    rake19 = ENV['RAKE19'] || 'rake1.9'
    system("rake clean cross compile RUBY_CC_VERSION=1.8.6 FAT_DIR=1.8")
    system("#{rake19} clean cross compile RUBY_CC_VERSION=1.9.1 FAT_DIR=1.9")
    File.open("lib/#{HOE.name}/#{HOE.name}.rb", 'wb') do |f|
      f.write <<-eoruby
require "#{HOE.name}/\#{RUBY_VERSION.sub(/\\.\\d+$/, '')}/#{HOE.name}"
      eoruby
    end
    HOE.spec.extensions = []
    HOE.spec.platform = 'x86-mswin32'
    HOE.spec.files += Dir["lib/#{HOE.name}/#{HOE.name}.rb"]
    HOE.spec.files += Dir["lib/#{HOE.name}/1.{8,9}/*"]
    HOE.spec.files += Dir["ext/nokogiri/*.dll"]
  end
  CLOBBER.include("lib/nokogiri/nokogiri.rb")
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
  ['valgrind', 'valgrind_mem', 'valgrind_mem0', 'coverage'].each do |task_name|
    Rake::Task["test:#{task_name}"].prerequisites << :compile
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
