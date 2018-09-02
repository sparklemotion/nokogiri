source 'https://rubygems.org'

# Nokogiri depends on pkg-config when built with system libraries but it
# doesn't declare this dependency. Unfortunately, bundler provides no way to
# declare additional dependencies and it will install dependencies in
# alphabetical order so it tries to install Nokogiri before pkg-config and
# this fails.
gem 'fix-dep-order', :path => 'scripts'
gem 'nokogiri', '>= 1.8'

group :development, :test do
  gem 'minitest'
  gem 'rake'
  gem 'rake-compiler'
end

