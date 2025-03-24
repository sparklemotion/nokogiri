# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development do
  # bootstrapping
  gem "bundler", "~> 2.3"
  gem "rake", "13.2.1"

  # building extensions
  gem "rake-compiler", "1.2.9"
  gem "rake-compiler-dock", "1.9.1"

  # parser generator
  gem "rexical", "1.0.8"

  # tests
  gem "minitest", "5.25.5"
  gem "minitest-parallel_fork", "2.0.0"
  gem "ruby_memcheck", "3.0.1"
  gem "rubyzip", "~> 2.4.1"
  gem "simplecov", "0.22.0"

  # rubocop
  gem "standard", "1.47.0"
  gem "rubocop-minitest", "0.37.1"
  gem "rubocop-packaging", "0.6.0"
  gem "rubocop-rake", "0.7.1"
end

# If Psych doesn't build, you can disable this group locally by running
# `bundle config set --local without rdoc`
# Then re-run `bundle install`.
group :rdoc do
  gem "rdoc", "6.13.0" unless RUBY_PLATFORM == "java" || ENV["CI"]
end
