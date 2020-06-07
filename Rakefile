# -*- ruby -*-
require 'hoe'

Hoe.plugin :bundler
Hoe.plugin :debugging
Hoe.plugin :gemspec
Hoe.plugin :git
Hoe.plugin :markdown

require 'shellwords'

require_relative "tasks/util"
require_relative "tasks/cross-ruby"

HOE = Hoe.spec 'nokogiri' do
  developer 'Aaron Patterson', 'aaronp@rubyforge.org'
  developer 'Mike Dalessio',   'mike.dalessio@gmail.com'
  developer 'Yoko Harada',     'yokolet@gmail.com'
  developer 'Tim Elliott',     'tle@holymonkey.com'
  developer 'Akinori MUSHA',   'knu@idaemons.org'
  developer 'John Shahid',     'jvshahid@gmail.com'
  developer 'Lars Kanis',      'lars@greiz-reinsdorf.de'

  license "MIT"

  self.urls = {
    "home" => "https://nokogiri.org",
    "bugs" => "https://github.com/sparklemotion/nokogiri/issues",
    "doco" => "https://nokogiri.org/rdoc/index.html",
    "clog" => "https://nokogiri.org/CHANGELOG.html",
    "code" => "https://github.com/sparklemotion/nokogiri",
  }

  self.markdown_linkify_files = FileList["*.md"]
  self.extra_rdoc_files = FileList['ext/nokogiri/*.c']

  self.clean_globs += [
    'nokogiri.gemspec',
    'lib/nokogiri/nokogiri.{bundle,jar,rb,so}',
    'lib/nokogiri/[0-9].[0-9]',
  ]
  self.clean_globs += Dir.glob("ports/*").reject { |d| d =~ %r{/archives$} }

  unless java?
    self.extra_deps += [
      ["mini_portile2", "~> 2.5.0"], # keep version in sync with extconf.rb
    ]
  end

  self.extra_dev_deps += [
    ["concourse", "~> 0.32"],
    ["hoe", ["~> 3.22", ">= 3.22.1"]],
    ["hoe-bundler", "~> 1.2"],
    ["hoe-debugging", "~> 2.0"],
    ["hoe-gemspec", "~> 1.0"],
    ["hoe-git", "~> 1.6"],
    ["hoe-markdown", "~> 1.1"],
    ["minitest", "~> 5.8"],
    ["racc", "~> 1.4.14"],
    ["rake", "~> 13.0"],
    ["rake-compiler", "~> 1.1"],
    ["rake-compiler-dock", "~> 1.0"],
    ["rexical", "~> 1.0.5"],
    ["rubocop", "~> 0.73"],
    ["simplecov", "~> 0.16"],
  ]

  self.spec_extras = {
    :extensions => ["ext/nokogiri/extconf.rb"],
    :required_ruby_version => '>= 2.4.0'
  }

  self.testlib = :minitest
  self.test_prelude = 'require "helper"' # ensure simplecov gets loaded before anything else
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
    ext.cross_compile  = true
    ext.cross_platform = CROSS_RUBIES.map(&:platform).uniq
    ext.cross_config_options << "--enable-cross-build"
    ext.cross_compiling do |spec|
      libs = dependencies.map { |name, dep| "#{name}-#{dep["version"]}" }.join(', ')

      spec.post_install_message = <<-EOS
Nokogiri is built with the packaged libraries: #{libs}.
      EOS
      spec.files.reject! { |path| File.fnmatch?('ports/*', path) }
      spec.dependencies.reject! { |dep| dep.name=='mini_portile2' }
    end
  end
end

require_relative "tasks/concourse"
require_relative "tasks/css-generate"
require_relative "tasks/debug"
require_relative "tasks/docker"
require_relative "tasks/docs-linkify"
require_relative "tasks/rubocop"
require_relative "tasks/set-version-to-timestamp"

# vim: syntax=Ruby
