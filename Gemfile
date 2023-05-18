# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development do
  # bootstrapping
  gem "bundler", "~> 2.3"
  gem "rake", "= 13.0.6"

  # building extensions
  gem "rake-compiler", "= 1.2.1"
  gem "rake-compiler-dock", "= 1.3.0"

  # documentation
  gem "hoe-markdown", "= 1.4.0"

  # parser generator
  gem "rexical", "= 1.0.7"

  # tests
  gem "minitest", "5.18.0"
  gem "minitest-reporters", "1.6.0"
  gem "ruby_memcheck", "1.3.2"
  gem "rubyzip", "~> 2.3.2"
  gem "simplecov", "= 0.21.2"

  # rubocop
  if Gem::Requirement.new("~> 3.0").satisfied_by?(Gem::Version.new(RUBY_VERSION))
    gem "rubocop", "1.51.0"
    gem "rubocop-minitest", "0.31.0"
    gem "rubocop-packaging", "0.5.2"
    gem "rubocop-performance", "1.17.1"
    gem "rubocop-rake", "= 0.6.0"
    gem "rubocop-shopify", "2.13.0"
  end
end

# If Psych doesn't build, you can disable this group locally by running
# `bundle config set --local without rdoc`
# Then re-run `bundle install`.
group :rdoc do
  gem "rdoc", "6.5.0"
end
