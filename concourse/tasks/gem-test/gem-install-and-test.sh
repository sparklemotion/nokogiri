#! /usr/bin/env bash

set -e -x -u

pushd gems

  gemfile=$(ls *.gem | head -n1)
  sha256sum ${gemfile}
  gem install ${gemfile}
  nokogiri -v

popd

pushd nokogiri

  bundle install
  echo 'gem "nokogiri"' >> Gemfile # jruby has issues running `rake test` outside of bundler

  bundle exec rake test # we're testing the installed gem, so we don't compile

popd

