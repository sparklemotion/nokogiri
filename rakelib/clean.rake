# frozen_string_literal: true

require "rake/clean"
CLEAN.add(
  "coverage",
  "ext/nokogiri/include",
  "lib/nokogiri/[0-9].[0-9]",
  "lib/nokogiri/nokogiri.{bundle,jar,rb,so}",
  "pkg",
  "tmp",
)
CLOBBER.add("ports/*").exclude(%r{ports/archives$})
