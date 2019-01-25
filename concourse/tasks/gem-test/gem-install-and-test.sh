#! /usr/bin/env bash

set -e -x -u

pushd gems

  gemfile=$(ls *.gem | head -n1)
  sha256sum ${gemfile}
  gem install ${gemfile}
  gem list -d nokogiri
  nokogiri -v

popd

pushd nokogiri

  bundle install --local || bundle install
  bundle add nokogiri
  bundle show nokogiri
  bundle exec rake test

popd

