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
  rake test # we're testing the installed gem, so we don't compile or use bundler

popd
