# -*- ruby -*-

require 'rubygems'
require 'rake'


kind = Config::CONFIG['DLEXT']
windows = RUBY_PLATFORM =~ /mswin/i ? true : false

LIB_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH << LIB_DIR

require 'vendor/hoe'

GENERATED_PARSER = "lib/nokogiri/css/generated_parser.rb"
GENERATED_TOKENIZER = "lib/nokogiri/css/generated_tokenizer.rb"

EXT = "ext/nokogiri/native.#{kind}"

require 'nokogiri/version'

HOE = Hoe.new('nokogiri', Nokogiri::VERSION) do |p|
  p.developer('Aaron Patterson', 'aaronp@rubyforge.org')
  p.developer('Mike Dalessio', 'mike.dalessio@gmail.com')
  p.clean_globs = [
    'ext/nokogiri/Makefile',
    'ext/nokogiri/*.{o,so,bundle,a,log,dll}',
    'ext/nokogiri/conftest.dSYM',
    GENERATED_PARSER,
    GENERATED_TOKENIZER,
    'cross',
  ]
  p.spec_extras = { :extensions => ["ext/nokogiri/extconf.rb"] }
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

  namespace :win32 do
    task :spec => ['build:win32'] do
      File.open("#{HOE.name}.gemspec", 'w') do |f|
        HOE.spec.files += Dir['ext/nokogiri/**.{dll,so}']
        if windows
          HOE.spec.platform = Gem::Platform::CURRENT
        else
          HOE.spec.platform = 'x86-mswin32-60'
        end
        HOE.spec.extensions = []
        f.write(HOE.spec.to_ruby)
      end
    end
  end

  namespace :jruby do
    task :spec => ['build'] do
      File.open("#{HOE.name}.gemspec", 'w') do |f|
        HOE.spec.platform = 'jruby'
        HOE.spec.extensions = []
        f.write(HOE.spec.to_ruby)
      end
    end
  end

  namespace :unix do
    task :spec do
      File.open("#{HOE.name}.gemspec", 'w') do |f|
        f.write(HOE.spec.to_ruby)
      end
    end
  end

  task :spec => ['gem:dev:spec']
end

desc "Run code-coverage analysis"
task :coverage do
  rm_rf "coverage"
  sh "rcov -x Library -I lib:test #{Dir[*HOE.test_globs].join(' ')}"
end

file GENERATED_PARSER => "lib/nokogiri/css/parser.y" do |t|
  begin
    racc = `which racc`.strip
    racc = "#{::Config::CONFIG['bindir']}/racc" if racc.empty?
    sh "#{racc} -o #{t.name} #{t.prerequisites.first}"
  rescue
    abort "need racc, get the tarball from http://i.loveruby.net/archive/racc/racc-1.4.5-all.tar.gz" 
  end
end

file GENERATED_TOKENIZER => "lib/nokogiri/css/tokenizer.rex" do |t|
  begin
    sh "frex -i --independent -o #{t.name} #{t.prerequisites.first}"
  rescue
    abort "need frex, sudo gem install aaronp-frex -s http://gems.github.com"   
  end
end

task 'ext/nokogiri/Makefile' do
  Dir.chdir('ext/nokogiri') do
    ruby "extconf.rb"
  end
end

task EXT => 'ext/nokogiri/Makefile' do
  Dir.chdir('ext/nokogiri') do
    sh 'make'
  end
end

if RUBY_PLATFORM == 'java'
  task :build => [GENERATED_PARSER, GENERATED_TOKENIZER]
else
  task :build => [EXT, GENERATED_PARSER, GENERATED_TOKENIZER]
end

namespace :build do
  namespace :win32 do
    file 'cross/bin/ruby.exe' => ['cross/ruby-1.8.6-p287'] do
      Dir.chdir('cross/ruby-1.8.6-p287') do
        str = ''
        File.open('Makefile.in', 'rb') do |f|
          f.each_line do |line|
            if line =~ /^\s*ALT_SEPARATOR =/
              str += "\t\t    " + 'ALT_SEPARATOR = "\\\\\"; \\'
              str += "\n"
            else
              str += line
            end
          end
        end
        File.open('Makefile.in', 'wb') { |f| f.write str }
        buildopts = if File.exists?('/usr/bin/i586-mingw32msvc-gcc')
                      "--host=i586-mingw32msvc --target=i386-mingw32 --build=i686-linux"
                    else
                      "--host=i386-mingw32 --target=i386-mingw32"
                    end
        sh(<<-eocommand)
          env ac_cv_func_getpgrp_void=no \
            ac_cv_func_setpgrp_void=yes \
            rb_cv_negative_time_t=no \
            ac_cv_func_memcmp_working=yes \
            rb_cv_binary_elf=no \
            ./configure \
            #{buildopts} \
            --prefix=#{File.expand_path(File.join(Dir.pwd, '..'))}
        eocommand
        sh 'make'
        sh 'make install'
      end
    end

    desc 'build cross compiled ruby'
    task :ruby => 'cross/bin/ruby.exe'
  end

  desc 'build nokogiri for win32'
  task :win32 => [GENERATED_PARSER, GENERATED_TOKENIZER, 'build:externals', 'build:win32:ruby'] do
    dash_i = File.expand_path(
      File.join(File.dirname(__FILE__), 'cross/lib/ruby/1.8/i386-mingw32/')
    )
    Dir.chdir('ext/nokogiri') do
      ruby " -I #{dash_i} extconf.rb"
      sh 'make'
    end
    dlls = Dir[File.join(File.dirname(__FILE__), 'cross', '**/*.dll')]
    dlls.each do |dll|
      next if dll =~ /ruby/
      cp dll, 'ext/nokogiri'
    end
  end

  libs = %w{
    iconv-1.9.2.win32
    zlib-1.2.3.win32
    libxml2-2.7.2.win32
    libxslt-1.1.24.win32
  }

  libs.each do |lib|
    file "stash/#{lib}.zip" do |t|
      puts "downloading #{lib}"
      FileUtils.mkdir_p('stash')
      Dir.chdir('stash') do 
        url = "http://www.zlatkovic.com/pub/libxml/#{lib}.zip"
        system("wget #{url} || curl -O #{url}")
      end
    end
    file "cross/#{lib}" => ["stash/#{lib}.zip"] do |t|
      puts "unzipping #{lib}.zip"
      FileUtils.mkdir_p('cross')
      Dir.chdir('cross') do
        sh "unzip ../stash/#{lib}.zip"
        sh "touch #{lib}"
      end
    end
  end

  file "stash/ruby-1.8.6-p287.tar.gz" do |t|
    puts "downloading ruby"
    FileUtils.mkdir_p('stash')
    Dir.chdir('stash') do 
      url = ("ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.6-p287.tar.gz")
      system("wget #{url} || curl -O #{url}")
    end
  end
  file 'cross/ruby-1.8.6-p287' => ["stash/ruby-1.8.6-p287.tar.gz"] do |t|
    puts "unzipping ruby"
    FileUtils.mkdir_p('cross')
    Dir.chdir('cross') do
      sh "tar zxvf ../stash/ruby-1.8.6-p287.tar.gz"
    end
  end

  task :externals => libs.map { |x| "cross/#{x}" } + ['cross/ruby-1.8.6-p287']
end

desc "set environment variables to build and/or test with debug options"
task :debug do
  ENV['NOKOGIRI_DEBUG'] = "true"
  ENV['CFLAGS'] ||= ""
  ENV['CFLAGS'] += " -DDEBUG"
end

def test_suite_cmdline
  require 'find'
  match = ENV['MATCH'] ? /#{ENV['MATCH']}/ : /./

  files = []
  Find.find("test") do |f|
    basename = File.basename(f)

    files << f if basename =~ /.*test.*\.rb$/ && basename =~ match
  end
  cmdline = "ruby -w -I.:lib:ext:test -rtest/unit -e '%w[#{files.join(' ')}].each {|f| require f}'"
end

namespace :test do
  # partial-loads-ok and undef-value-errors necessary to ignore
  # spurious (and eminently ignorable) warnings from the ruby
  # interpreter
  VALGRIND_BASIC_OPTS = "--num-callers=50 --error-limit=no --partial-loads-ok=yes --undef-value-errors=no"

  desc "run test suite under valgrind with basic ruby options"
  task :valgrind => :build do
    cmdline = "valgrind #{VALGRIND_BASIC_OPTS} #{test_suite_cmdline}"
    puts cmdline
    system cmdline
  end

  desc "run test suite under valgrind with memory-fill ruby options"
  task :valgrind_mem => :build do
    # fill malloced memory with "m" and freed memory with "f"
    cmdline = "valgrind #{VALGRIND_BASIC_OPTS} --freelist-vol=100000000 --malloc-fill=6D --free-fill=66 #{test_suite_cmdline}"
    puts cmdline
    system cmdline
  end

  desc "run test suite under valgrind with memory-zero ruby options"
  task :valgrind_mem0 => :build do
    # fill malloced and freed memory with 0
    cmdline = "valgrind #{VALGRIND_BASIC_OPTS} --freelist-vol=100000000 --malloc-fill=00 --free-fill=00 #{test_suite_cmdline}"
    puts cmdline
    system cmdline
  end

  desc "run test suite under gdb"
  task :gdb => :build do
    cmdline = "gdb --args #{test_suite_cmdline}"
    puts cmdline
    system cmdline
  end

  desc "run test suite with aggressive GC"
  task :gc => :build do
    ENV['NOKOGIRI_GC'] = "true"
    Rake::Task["test"].invoke
  end

  desc "find call-seq in the rdoc"
  task :rdoc => 'docs' do
    Dir['doc/**/*.html'].each { |docfile|
      next if docfile =~ /\.src/
      puts "FAIL: #{docfile}" if File.read(docfile) =~ /call-seq/
    }
  end
end

namespace :install do
  desc "Install frex and racc for development"
  task :deps => %w(frex racc)

  directory "stash"

  file "stash/racc-1.4.5-all.tar.gz" => "stash" do |t|
    puts "Downloading racc to #{t.name}..."

    Dir.chdir File.dirname(t.name) do
      url = "http://i.loveruby.net/archive/racc/racc-1.4.5-all.tar.gz"
      system "wget #{url} || curl -O #{url}"
    end
  end

  task :racc => "stash/racc-1.4.5-all.tar.gz" do |t|
    sh "tar xvf #{t.prerequisites.first} -C stash"

    Dir.chdir "stash/#{File.basename(t.prerequisites.first, ".tar.gz")}" do
      sh "ruby setup.rb config"
      sh "ruby setup.rb setup"
      sh "sudo ruby setup.rb install"
    end

    puts "The racc binary is likely in #{::Config::CONFIG["bindir"]}."
  end

  task :frex do
    sh "sudo gem install aaronp-frex -s http://gems.github.com"
  end
end

# Only do this on unix, since we can't build on windows
unless windows
  Rake::Task[:test].prerequisites << :build
  Rake::Task[:check_manifest].prerequisites << GENERATED_PARSER
  Rake::Task[:check_manifest].prerequisites << GENERATED_TOKENIZER
end

# vim: syntax=Ruby
