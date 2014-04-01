# -*- ruby -*-
require 'rubygems'
require 'shellwords'

gem 'hoe'
require 'hoe'
Hoe.plugin :debugging
Hoe.plugin :git
Hoe.plugin :gemspec
Hoe.plugin :bundler
Hoe.add_include_dirs '.'

GENERATED_PARSER    = "lib/nokogiri/css/parser.rb"
GENERATED_TOKENIZER = "lib/nokogiri/css/tokenizer.rb"
CROSS_DIR           =  File.join(File.dirname(__FILE__), 'ports')

def java?
  /java/ === RUBY_PLATFORM
end

ENV['LANG'] = "en_US.UTF-8" # UBUNTU 10.04, Y U NO DEFAULT TO UTF-8?

CrossRuby = Struct.new(:version, :host) {
  def ver
    @ver ||= version[/\A[^-]+/]
  end

  def api_ver_suffix
    case ver
    when /\A([2-9])\.([0-9])\./
      "#{$1}#{$2}0"
    when /\A1\.9\./
      '191'
    else
      raise "unsupported version: #{ver}"
    end
  end

  def platform
    @platform ||=
      case host
      when /\Ax86_64-/
        'x64-mingw32'
      when /\Ai[3-6]86-/
        'x86-mingw32'
      else
        raise "unsupported host: #{host}"
      end
  end

  def target
    case host
    when /\Ax86_64-/
      'pei-x86-64'
    when /\Ai[3-6]86-/
      'pei-i386'
    else
      raise "unsupported host: #{host}"
    end
  end

  def libruby_dll
    case platform
    when 'x64-mingw32'
      "x64-msvcrt-ruby#{api_ver_suffix}.dll"
    when 'x86-mingw32'
      "msvcrt-ruby#{api_ver_suffix}.dll"
    end
  end

  def dlls
    [
      'kernel32.dll',
      'msvcrt.dll',
      'ws2_32.dll',
      *(case
        when ver >= '2.0.0'
          'user32.dll'
        end),
      libruby_dll
    ]
  end
}

CROSS_RUBIES = File.read('.cross_rubies').lines.flat_map { |line|
  case line
  when /\A([^#]+):([^#]+)/
    CrossRuby.new($1, $2)
  else
    []
  end
}

require 'tasks/nokogiri.org'

HOE = Hoe.spec 'nokogiri' do
  developer 'Aaron Patterson', 'aaronp@rubyforge.org'
  developer 'Mike Dalessio',   'mike.dalessio@gmail.com'
  developer 'Yoko Harada',     'yokolet@gmail.com'
  developer 'Tim Elliott',     'tle@holymonkey.com'
  developer 'Akinori MUSHA',   'knu@idaemons.org'

  self.readme_file  = ['README',    ENV['HLANG'], 'rdoc'].compact.join('.')
  self.history_file = ['CHANGELOG', ENV['HLANG'], 'rdoc'].compact.join('.')

  self.extra_rdoc_files = FileList['*.rdoc','ext/nokogiri/*.c']


  self.clean_globs += [
    'nokogiri.gemspec',
    'lib/nokogiri/nokogiri.{bundle,jar,rb,so}',
    'lib/nokogiri/[0-9].[0-9]',
    'ports/*.installed',
    'ports/{i[3-6]86,x86_64}-{w64-,}mingw32*',
    'ports/libxml2',
    'ports/libxslt',
    # GENERATED_PARSER,
    # GENERATED_TOKENIZER
  ]

  unless java?
    self.extra_deps += [
      ["mini_portile",    "~> 0.5.2"],
    ]
  end

  self.extra_dev_deps += [
    ["hoe-bundler",     ">= 1.1"],
    ["hoe-debugging",   ">= 1.0.3"],
    ["hoe-gemspec",     ">= 1.0"],
    ["hoe-git",         ">= 1.4"],
    ["minitest",        "~> 2.2.2"],
    ["rake",            ">= 0.9"],
    ["rake-compiler",   "~> 0.9.2"],
    ["racc",            ">= 1.4.6"],
    ["rexical",         ">= 1.0.5"]
  ]

  if java?
    self.spec_extras = { :platform => 'java' }
  else
    self.spec_extras = {
      :extensions => ["ext/nokogiri/extconf.rb"],
      :required_ruby_version => '>= 1.9.2'
    }
  end

  self.testlib = :minitest
end
HOE.spec.licenses = ['MIT']

# ----------------------------------------

def add_file_to_gem relative_path
  target_path = File.join gem_build_path, relative_path
  target_dir = File.dirname(target_path)
  mkdir_p target_dir unless File.directory?(target_dir)
  rm_f target_path
  safe_ln relative_path, target_path
  HOE.spec.files += [relative_path]
end

def gem_build_path
  File.join 'pkg', HOE.spec.full_name
end

if java?
  # TODO: clean this section up.
  require "rake/javaextensiontask"
  Rake::JavaExtensionTask.new("nokogiri", HOE.spec) do |ext|
    jruby_home = RbConfig::CONFIG['prefix']
    ext.ext_dir = 'ext/java'
    ext.lib_dir = 'lib/nokogiri'
    ext.source_version = '1.6'
    ext.target_version = '1.6'
    jars = ["#{jruby_home}/lib/jruby.jar"] + FileList['lib/*.jar']
    ext.classpath = jars.map { |x| File.expand_path x }.join ':'
  end

  task gem_build_path => [:compile] do
    add_file_to_gem 'lib/nokogiri/nokogiri.jar'
  end
else
  begin
    require 'rake/extensioncompiler'
    # Ensure mingw compiler is installed
    Rake::ExtensionCompiler.mingw_host
    mingw_available = true
  rescue
    puts "WARNING: cross compilation not available: #{$!}"
    mingw_available = false
  end
  require "rake/extensiontask"

  HOE.spec.files.reject! { |f| f =~ %r{\.(java|jar)$} }

  dependencies = YAML.load_file("dependencies.yml")

  task gem_build_path do
    %w[libxml2 libxslt].each do |lib|
      version = dependencies[lib]
      archive = File.join("ports", "archives", "#{lib}-#{version}.tar.gz")
      add_file_to_gem archive
      patchesdir = File.join("ports", "patches", lib)
      patches = `#{['git', 'ls-files', patchesdir].shelljoin}`.split("\n").grep(/\.patch\z/)
      patches.each { |patch|
        add_file_to_gem patch
      }
      (untracked = Dir[File.join(patchesdir, '*.patch')] - patches).empty? or
        at_exit {
          untracked.each { |patch|
            puts "** WARNING: untracked patch file not added to gem: #{patch}"
          }
        }
    end
  end

  Rake::ExtensionTask.new("nokogiri", HOE.spec) do |ext|
    ext.lib_dir = File.join(*['lib', 'nokogiri', ENV['FAT_DIR']].compact)
    ext.config_options << ENV['EXTOPTS']
    if mingw_available
      ext.cross_compile  = true
      ext.cross_platform = CROSS_RUBIES.map(&:platform).uniq
      ext.cross_config_options << "--enable-cross-build"
      ext.cross_compiling do |spec|
        libs = dependencies.map { |name, version| "#{name}-#{version}" }.join(', ')

        spec.post_install_message = <<-EOS
Nokogiri is built with the packaged libraries: #{libs}.
        EOS
        spec.files.reject! { |path| File.fnmatch?('ports/*', path) }
      end
    end
  end
end

# To reduce the gem file size strip mingw32 dlls before packaging
ENV['RUBY_CC_VERSION'].to_s.split(':').each do |ruby_version|
  task "copy:nokogiri:x86-mingw32:#{ruby_version}" do |t|
    sh "i686-w64-mingw32-strip -S tmp/x86-mingw32/stage/lib/nokogiri/#{ruby_version[/^\d+\.\d+/]}/nokogiri.so"
  end

  task "copy:nokogiri:x64-mingw32:#{ruby_version}" do |t|
    sh "x86_64-w64-mingw32-strip -S tmp/x64-mingw32/stage/lib/nokogiri/#{ruby_version[/^\d+\.\d+/]}/nokogiri.so"
  end
end

# ----------------------------------------

desc "Generate css/parser.rb and css/tokenizer.rex"
task 'generate' => [GENERATED_PARSER, GENERATED_TOKENIZER]
task 'gem:spec' => 'generate' if Rake::Task.task_defined?("gem:spec")

# This is a big hack to make sure that the racc and rexical
# dependencies in the Gemfile are constrainted to ruby platforms
# (i.e. MRI and Rubinius). There's no way to do that through hoe,
# and any solution will require changing hoe and hoe-bundler.
old_gemfile_task = Rake::Task['bundler:gemfile'] rescue nil
task 'bundler:gemfile' do
  old_gemfile_task.invoke if old_gemfile_task

  lines = File.open('Gemfile', 'r') { |f| f.readlines }.map do |line|
    line =~ /racc|rexical/ ? "#{line.strip}, :platform => :ruby" : line
  end
  File.open('Gemfile', 'w') { |f| lines.each { |line| f.puts line } }
end

file GENERATED_PARSER => "lib/nokogiri/css/parser.y" do |t|
  racc = RbConfig::CONFIG['target_os'] =~ /mswin32/ ? '' : `which racc`.strip
  racc = "#{::RbConfig::CONFIG['bindir']}/racc" if racc.empty?
  racc = %x{command -v racc}.strip if racc.empty?
  sh "#{racc} -l -o #{t.name} #{t.prerequisites.first}"
end

file GENERATED_TOKENIZER => "lib/nokogiri/css/tokenizer.rex" do |t|
  sh "rex --independent -o #{t.name} #{t.prerequisites.first}"
end

[:compile, :check_manifest].each do |task_name|
  Rake::Task[task_name].prerequisites << GENERATED_PARSER
  Rake::Task[task_name].prerequisites << GENERATED_TOKENIZER
end

# ----------------------------------------

desc "set environment variables to build and/or test with debug options"
task :debug do
  ENV['NOKOGIRI_DEBUG'] = "true"
  ENV['CFLAGS'] ||= ""
  ENV['CFLAGS'] += " -DDEBUG"
end

require 'tasks/test'

task :java_debug do
  ENV['JAVA_OPTS'] = '-Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=y' if java? && ENV['JAVA_DEBUG']
end

if java?
  task :test_18 => :test
  task :test_19 do
    ENV['JRUBY_OPTS'] = "--1.9"
    Rake::Task["test"].invoke
  end
end

Rake::Task[:test].prerequisites << :compile
Rake::Task[:test].prerequisites << :java_debug
Rake::Task[:test].prerequisites << :check_extra_deps unless java?

if Hoe.plugins.include?(:debugging)
  ['valgrind', 'valgrind:mem', 'valgrind:mem0'].each do |task_name|
    Rake::Task["test:#{task_name}"].prerequisites << :compile
  end
end

# ----------------------------------------

def verify_dll(dll, fformat, dll_imports=[])
  host = 'x86_64-w64-mingw32'
  dump = `env LANG=C #{host}-objdump -p #{dll.inspect}`
  raise "unexpected file format for generated dll #{dll}" unless dump =~ /file format #{fformat}\s/
  raise "export function Init_nokogiri not in dll #{dll}" unless dump =~ /Table.*\sInit_nokogiri\s/mi

  # Verify that the expected DLL dependencies match the actual dependencies
  # and that no further dependencies exist.
  dll_imports_is = dump.scan(/DLL Name: (.*)$/).map(&:first).map(&:downcase).uniq
  if dll_imports_is.sort != dll_imports.sort
    raise "unexpected dll imports #{dll_imports_is.inspect} in #{dll}"
  end
  puts "#{dll}: Looks good!"
end

desc "build a windows gem without all the ceremony."
task "gem:windows" do
  ruby_cc_version = CROSS_RUBIES.map(&:ver).uniq.join(":") # e.g., "1.9.3:2.0.0"
  rake_compiler_config_path = "#{ENV['HOME']}/.rake-compiler/config.yml"

  unless File.exists? rake_compiler_config_path
    raise "rake-compiler has not installed any cross rubies. try running 'env --unset=HOST rake-compiler cross-ruby VERSION=#{CROSS_RUBIES.first.version}'"
  end
  rake_compiler_config = YAML.load_file(rake_compiler_config_path)

  # check that rake-compiler config contains the right patchlevels. see #279 for background,
  # and http://blog.mmediasys.com/2011/01/22/rake-compiler-updated-list-of-supported-ruby-versions-for-cross-compilation/
  # for more up-to-date docs.
  CROSS_RUBIES.each do |cross_ruby|
    rbconfig = "rbconfig-#{cross_ruby.platform}-#{cross_ruby.ver}"
    case rake_compiler_config[rbconfig]
    when %r{/#{Regexp.quote(cross_ruby.version)}/}
      # ok
    when %r{/#{Regexp.quote(cross_ruby.ver)}(?:-p\d+)/}
      raise "rake-compiler '#{rbconfig}' not #{cross_ruby.version}. try running 'env --unset=HOST rake-compiler cross-ruby VERSION=#{cross_ruby.version}'"
    end
  end

  sh("env RUBY_CC_VERSION=#{ruby_cc_version} rake cross native gem") || raise("build failed!")

  Rake::Task["gem:windows:verify_dll"].execute
end

desc "do some sanity checks on the built DLLs."
task "gem:windows:verify_dll" do
  CROSS_RUBIES.each do |cross_ruby|
    dll = "tmp/#{cross_ruby.platform}/nokogiri/#{cross_ruby.ver}/nokogiri.so"

    if File.file?(dll)
      verify_dll dll, cross_ruby.target, cross_ruby.dlls
    else
      puts "#{dll}: not found."
    end
  end
end

# vim: syntax=Ruby
