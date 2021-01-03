# frozen_string_literal: true
require "bundler"
Bundler.load_gemspec("nokogiri.gemspec")

require "rubygems/package_task"
Gem::PackageTask.new(NOKOGIRI_SPEC).define

require "rake/clean"
CLEAN.add(
  "concourse/images/*.generated",
  "coverage",
  "doc",
  "ext/nokogiri/include",
  "lib/nokogiri/[0-9].[0-9]",
  "lib/nokogiri/nokogiri.{bundle,jar,rb,so}",
  "pkg",
  "tmp",
)
CLOBBER.add("ports/*").exclude(%r{ports/archives$})
CLOBBER.add(".yardoc")
CLOBBER.add("gems")

require "hoe/markdown"
Hoe::Markdown::Standalone.new("nokogiri").define_markdown_tasks

require "yard"
YARD::Rake::YardocTask.new("doc") do |t|
 t.files = ["lib/**/*.rb", "ext/nokogiri/*.c"]
 t.options = ["--embed-mixins", "--main=README.md"]
end

task default: [:rubocop, :compile, :test]
