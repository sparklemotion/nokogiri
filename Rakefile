# frozen_string_literal: true

#
# Tasks are all loaded from `rakelib/*.rake`.
# You may want to use `rake -T` to see what's available.
#
require "bundler"
NOKOGIRI_SPEC = Bundler.load_gemspec("nokogiri.gemspec")

task default: [:rubocop, :gumbo, :compile, :test]
