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
  rake test

popd
