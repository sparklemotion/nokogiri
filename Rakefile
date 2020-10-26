require "hoe"

Hoe.plugin :bundler
Hoe.plugin :debugging
Hoe.plugin :gemspec
Hoe.plugin :git
Hoe.plugin :markdown

require_relative "tasks/util"

HOE = Hoe.spec "nokogiri" do |hoe|
  hoe.author = [
    "Mike Dalessio",
    "Aaron Patterson",
    "John Shahid",
    "Yoko Harada",
    "Akinori MUSHA",
    "Lars Kanis",
    "Tim Elliott",
  ]

  hoe.email = "nokogiri-talk@googlegroups.com"

  hoe.license "MIT"

  hoe.urls = {
    "home" => "https://nokogiri.org",
    "bugs" => "https://github.com/sparklemotion/nokogiri/issues",
    "doco" => "https://nokogiri.org/rdoc/index.html",
    "clog" => "https://nokogiri.org/CHANGELOG.html",
    "code" => "https://github.com/sparklemotion/nokogiri",
  }

  hoe.markdown_linkify_files = FileList["*.md"]
  hoe.extra_rdoc_files = FileList["ext/nokogiri/*.c"]

  hoe.clean_globs += [
    "nokogiri.gemspec",
    "lib/nokogiri/nokogiri.{bundle,jar,rb,so}",
    "lib/nokogiri/[0-9].[0-9]",
  ]
  hoe.clean_globs += Dir.glob("ports/*").reject { |d| d =~ %r{/archives$} }

  unless java?
    hoe.extra_deps += [
      ["mini_portile2", "~> 2.5.0"], # keep version in sync with extconf.rb
    ]
  end

  hoe.extra_dev_deps += [
    ["concourse", "~> 0.38"],
    ["hoe", ["~> 3.22", ">= 3.22.1"]],
    ["hoe-bundler", "~> 1.2"],
    ["hoe-debugging", "~> 2.0"],
    ["hoe-gemspec", "~> 1.0"],
    ["hoe-git", "~> 1.6"],
    ["hoe-markdown", "~> 1.1"],
    ["minitest", "~> 5.8"],
    ["racc", "~> 1.5.0"],
    ["rake", "~> 13.0"],
    ["rake-compiler", "~> 1.1"],
    ["rake-compiler-dock", "~> 1.0"],
    ["rexical", "~> 1.0.5"],
    ["rubocop", "~> 0.88"],
    ["simplecov", "~> 0.17.0"], # locked due to https://github.com/codeclimate/test-reporter/issues/413
  ]

  hoe.spec_extras = {
    :extensions => ["ext/nokogiri/extconf.rb"],
    :required_ruby_version => ">= 2.4.0"
  }

  hoe.testlib = :minitest
  hoe.test_prelude = %q(require "helper") # ensure simplecov gets loaded before anything else
end

require_relative "tasks/cross-ruby"
require_relative "tasks/concourse"
require_relative "tasks/css-generate"
require_relative "tasks/debug"
require_relative "tasks/docker"
require_relative "tasks/rubocop"
require_relative "tasks/set-version-to-timestamp"

# work around Hoe's inflexibility about the default tasks
Rake::Task[:default].prerequisites.unshift("compile")
Rake::Task[:default].prerequisites.unshift("rubocop")
