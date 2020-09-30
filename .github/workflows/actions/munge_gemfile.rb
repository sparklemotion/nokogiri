# frozen_string_literal: true

CONTENTS = <<~RUBY
  source 'https://rubygems.org'
  gemspec
RUBY

File.open('Gemfile', 'wb') { |f| f.puts CONTENTS }
