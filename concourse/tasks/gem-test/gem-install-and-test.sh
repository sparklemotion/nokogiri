#! /usr/bin/env bash

test -e /etc/os-release && cat /etc/os-release

set -e -x -u

pushd gems

  gemfile=$(ls *.gem | head -n1)
  sha256sum ${gemfile}
  gem install ${gemfile}
  gem list -d nokogiri
  nokogiri -v

popd

pushd nokogiri

  export BUNDLE_CACHE_PATH="${BUNDLE_APP_CONFIG}/cache"
  bundle -v
  bundle config

  bundle add nokogiri --skip-install
  bundle install --local || bundle install
  bundle info nokogiri

  bundle exec rake test:cmd > run-test
  rm -rf lib ext # ensure we can't use the local files
  bundle exec bash run-test

popd
