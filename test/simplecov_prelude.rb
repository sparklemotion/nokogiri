# frozen_string_literal: true

# https://github.com/simplecov-ruby/simplecov/issues/1032
unless ENV["RUBY_MEMCHECK_RUNNING"] || ENV["NCPU"].to_i > 1
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    enable_coverage :branch
  end
end
