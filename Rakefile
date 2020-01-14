# -*- ruby -*-
require 'rubygems'
require 'shellwords'

gem 'hoe'
require 'hoe'
Hoe.plugin :debugging
Hoe.plugin :git
Hoe.plugin :gemspec
Hoe.plugin :bundler

GENERATED_PARSER    = "lib/nokogiri/css/parser.rb"
GENERATED_TOKENIZER = "lib/nokogiri/css/tokenizer.rb"

def java?
  /java/ === RUBY_PLATFORM
end

ENV['LANG'] = "en_US.UTF-8" # UBUNTU 10.04, Y U NO DEFAULT TO UTF-8?

CrossRuby = Struct.new(:version, :host) {
  def ver
    @ver ||= version[/\A[^-]+/]
  end

  def minor_ver
    @minor_ver ||= ver[/\A\d\.\d(?=\.)/]
  end

  def api_ver_suffix
    case minor_ver
    when nil
      raise "unsupported version: #{ver}"
    else
      minor_ver.delete('.') << '0'
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

  def tool(name)
    (@binutils_prefix ||=
      case platform
      when 'x64-mingw32'
        'x86_64-w64-mingw32-'
      when 'x86-mingw32'
        'i686-w64-mingw32-'
      end) + name
  end

  def target
    case platform
    when 'x64-mingw32'
      'pei-x86-64'
    when 'x86-mingw32'
      'pei-i386'
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

ENV['RUBY_CC_VERSION'] ||= CROSS_RUBIES.map(&:ver).uniq.join(":")

HOE = Hoe.spec 'nokogiri' do
  developer 'Aaron Patterson', 'aaronp@rubyforge.org'
  developer 'Mike Dalessio',   'mike.dalessio@gmail.com'
  developer 'Yoko Harada',     'yokolet@gmail.com'
  developer 'Tim Elliott',     'tle@holymonkey.com'
  developer 'Akinori MUSHA',   'knu@idaemons.org'
  developer 'John Shahid',     'jvshahid@gmail.com'
  developer 'Lars Kanis',      'lars@greiz-reinsdorf.de'

  license "MIT"

  self.readme_file  = "README.md"
  self.history_file = "CHANGELOG.md"

  self.urls = {
    "home" => "https://nokogiri.org",
    "bugs" => "https://github.com/sparklemotion/nokogiri/issues",
    "doco" => "https://nokogiri.org/rdoc/index.html",
    "clog" => "https://nokogiri.org/CHANGELOG.html",
    "code" => "https://github.com/sparklemotion/nokogiri",
  }

  self.extra_rdoc_files = FileList['ext/nokogiri/*.c']

  self.clean_globs += [
    'nokogiri.gemspec',
    'lib/nokogiri/nokogiri.{bundle,jar,rb,so}',
    'lib/nokogiri/[0-9].[0-9]',
    'concourse/images/*.generated'
  ]
  self.clean_globs += Dir.glob("ports/*").reject { |d| d =~ %r{/archives$} }

  if java?
    self.extra_deps += [
      ['jar-dependencies', "~> 0.4.0"],
    ]
    def self.add_dependencies
      super

      # spec.requirements << 'jar com.sun.xml.bind.jaxb, isorelax, 20090621' # unknown where to find original 20041111
      spec.requirements << 'jar com.thaiopensource, jing, 20091111'
      # spec.requirements << 'jar nekohtml, nekodtd, 0.1.11' # FIXME,  not using jvshahid's fork!
      # spec.requirements << 'jar nekohtml, nekohtml, 1.9.6.2' # FIXME,  not using jvshahid's fork!
      spec.requirements << 'jar xalan, serializer, 2.7.2'
      spec.requirements << 'jar xalan, xalan, 2.7.2'
      spec.requirements << 'jar xerces, xercesImpl, 2.12.0'
      spec.requirements << 'jar xml-apis, xml-apis, 1.4.01'
    end
  else
    self.extra_deps += [
      ["mini_portile2",    "~> 2.4.0"], # keep version in sync with extconf.rb
    ]
  end

  self.extra_dev_deps += [
    ["concourse",          "~> 0.24"],
    ["hoe-bundler",        "~> 1.2"],
    ["hoe-debugging",      "~> 2.0"],
    ["hoe-gemspec",        "~> 1.0"],
    ["hoe-git",            "~> 1.6"],
    ["minitest",           "~> 5.8"],
    ["racc",               "~> 1.4.14"],
    ["rake",               "~> 12.0"],
    ["rake-compiler",      "~> 1.0.3"],
    ["rake-compiler-dock", "~> 0.7.0"],
    ["rexical",            "~> 1.0.5"],
    ["rubocop",            "~> 0.73"],
    ["simplecov",          "~> 0.16"],
  ]

  self.spec_extras = {
    :extensions => ["ext/nokogiri/extconf.rb"],
    :required_ruby_version => '>= 2.3.0'
  }

  self.testlib = :minitest
  self.test_prelude = 'require "helper"' # ensure simplecov gets loaded before anything else
end

# ----------------------------------------

def add_file_to_gem relative_source_path
  dest_path = File.join(gem_build_path, relative_source_path)
  dest_dir = File.dirname(dest_path)

  mkdir_p dest_dir unless Dir.exist?(dest_dir)
  rm_f dest_path if File.exist?(dest_path)
  safe_ln relative_source_path, dest_path

  HOE.spec.files << relative_source_path
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
    ext.debug = true if ENV['JAVA_DEBUG']
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
    mingw_available = false
  end
  require "rake/extensiontask"

  HOE.spec.files.reject! { |f| f =~ %r{\.(java|jar)$} }

  dependencies = YAML.load_file("dependencies.yml")

  task gem_build_path do
    %w[libxml2 libxslt].each do |lib|
      version = dependencies[lib]["version"]
      archive = File.join("ports", "archives", "#{lib}-#{version}.tar.gz")
      add_file_to_gem archive
      patchesdir = File.join("patches", lib)
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
        libs = dependencies.map { |name, dep| "#{name}-#{dep["version"]}" }.join(', ')

        spec.post_install_message = <<-EOS
Nokogiri is built with the packaged libraries: #{libs}.
        EOS
        spec.files.reject! { |path| File.fnmatch?('ports/*', path) }
      end
    end
  end
end

# ----------------------------------------

desc "Generate css/parser.rb and css/tokenizer.rex"
task 'generate' => [GENERATED_PARSER, GENERATED_TOKENIZER]
task 'gem:spec' => 'generate' if Rake::Task.task_defined?("gem:spec")
[:compile, :check_manifest].each do |task_name|
  Rake::Task[task_name].prerequisites << GENERATED_PARSER
  Rake::Task[task_name].prerequisites << GENERATED_TOKENIZER
end

file GENERATED_PARSER => "lib/nokogiri/css/parser.y" do |t|
  sh "racc -l -o #{t.name} #{t.prerequisites.first}"
end

file GENERATED_TOKENIZER => "lib/nokogiri/css/tokenizer.rex" do |t|
  sh "rex --independent -o #{t.name} #{t.prerequisites.first}"
end

# ----------------------------------------

desc "set environment variables to build and/or test with debug options"
task :debug do
  ENV['NOKOGIRI_DEBUG'] = "true"
  ENV['CFLAGS'] ||= ""
  ENV['CFLAGS'] += " -DDEBUG"
end

task :java_debug do
  ENV['JRUBY_OPTS'] = "#{ENV['JRUBY_OPTS']} --debug --dev"
  ENV['JAVA_OPTS'] = '-Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=y' if ENV['JAVA_DEBUG']
end
Rake::Task[:test].prerequisites << :java_debug

task :rubocop_security do
  sh "rubocop lib --only Security"
end
Rake::Task[:test].prerequisites << :rubocop_security

if Hoe.plugins.include?(:debugging)
  ['valgrind', 'valgrind:mem', 'valgrind:mem0'].each do |task_name|
    Rake::Task["test:#{task_name}"].prerequisites << :compile
  end
end

require 'concourse'
Concourse.new("nokogiri", fly_target: "ci") do |c|
  c.add_pipeline "nokogiri", "nokogiri.yml"
  c.add_pipeline "nokogiri-pr", "nokogiri-pr.yml"
  c.add_pipeline "nokogiri-v1.10.x", "nokogiri-v1.10.x.yml"
end

# ----------------------------------------

def verify_dll(dll, cross_ruby)
  dll_imports = cross_ruby.dlls
  dump = `#{['env', 'LANG=C', cross_ruby.tool('objdump'), '-p', dll].shelljoin}`
  raise "unexpected file format for generated dll #{dll}" unless /file format #{Regexp.quote(cross_ruby.target)}\s/ === dump
  raise "export function Init_nokogiri not in dll #{dll}" unless /Table.*\sInit_nokogiri\s/mi === dump

  # Verify that the expected DLL dependencies match the actual dependencies
  # and that no further dependencies exist.
  dll_imports_is = dump.scan(/DLL Name: (.*)$/).map(&:first).map(&:downcase).uniq
  if dll_imports_is.sort != dll_imports.sort
    raise "unexpected dll imports #{dll_imports_is.inspect} in #{dll}"
  end
  puts "#{dll}: Looks good!"
end

task :cross do
  rake_compiler_config_path = File.expand_path("~/.rake-compiler/config.yml")
  unless File.exists? rake_compiler_config_path
    raise "rake-compiler has not installed any cross rubies. Use rake-compiler-dock or 'rake gem:windows' for building binary windows gems."
  end

  CROSS_RUBIES.each do |cross_ruby|
    task "tmp/#{cross_ruby.platform}/nokogiri/#{cross_ruby.ver}/nokogiri.so" do |t|
      # To reduce the gem file size strip mingw32 dlls before packaging
      sh [cross_ruby.tool('strip'), '-S', t.name].shelljoin
      verify_dll t.name, cross_ruby
    end
  end
end

desc "build a windows gem without all the ceremony"
task "gem:windows" do
  require "rake_compiler_dock"
  RakeCompilerDock.sh "gem install bundler && bundle && rake cross native gem MAKE='nice make -j`nproc`' RUBY_CC_VERSION=#{ENV['RUBY_CC_VERSION']}"
end

desc "build a jruby gem with docker"
task "gem:jruby" do
  require "rake_compiler_dock"
  RakeCompilerDock.sh "gem install bundler && bundle && rake java gem", rubyvm: 'jruby'
end

require_relative "tasks/docker"

# vim: syntax=Ruby
