# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development do
  # bootstrapping
  gem "bundler", "~> 2.3"
  gem "rake", "= 13.0.6"

  # building extensions
  gem "rake-compiler", "= 1.2.0"
  gem "rake-compiler-dock", "= 1.2.2"

  # documentation
  gem "hoe-markdown", "= 1.4.0"
  gem "rdoc", "6.5.0"
  gem "psych", "~> 4.0" # psych 5 isn't building in places yet https://github.com/ruby/setup-ruby/issues/409

  # parser generator
  gem "rexical", "= 1.0.7"

  # tests
  gem "minitest", "= 5.16.3"
  gem "minitest-reporters", "= 1.5.0"
  gem "ruby_memcheck", "1.2.0" unless RUBY_PLATFORM == "java"
  gem "simplecov", "0.22.0"

  # rubocop
  if Gem::Requirement.new("~> 3.0").satisfied_by?(Gem::Version.new(RUBY_VERSION))
    gem "rubocop", "1.40.0"
    gem "rubocop-minitest", "0.25.0"
    gem "rubocop-performance", "1.15.1"
    gem "rubocop-rake", "= 0.6.0"
    gem "rubocop-shopify", "= 2.9.0"
  end
end
