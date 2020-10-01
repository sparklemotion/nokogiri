# -*- ruby -*-
require 'hoe'

Hoe.plugin :bundler
Hoe.plugin :debugging
Hoe.plugin :gemspec
Hoe.plugin :git
Hoe.plugin :markdown

require 'shellwords'

require_relative "tasks/util"

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
    ["concourse", "~> 0.37"],
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
    ["rubocop", "~> 0.88"],
    ["simplecov", "~> 0.17.0"], # locked due to https://github.com/codeclimate/test-reporter/issues/413
  ]

  self.spec_extras = {
    :extensions => ["ext/nokogiri/extconf.rb"],
    :required_ruby_version => '>= 2.4.0'
  }

  self.testlib = :minitest
  self.test_prelude = 'require "helper"' # ensure simplecov gets loaded before anything else
end

require_relative "tasks/cross-ruby"
require_relative "tasks/concourse"
require_relative "tasks/css-generate"
require_relative "tasks/debug"
require_relative "tasks/docker"
require_relative "tasks/docs-linkify"
require_relative "tasks/rubocop"
require_relative "tasks/set-version-to-timestamp"

# work around Hoe's inflexibility about the default tasks
Rake::Task[:default].prerequisites.unshift("compile")
Rake::Task[:default].prerequisites.unshift("rubocop")

# vim: syntax=Ruby
