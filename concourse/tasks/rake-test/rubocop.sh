#! /usr/bin/env bash

set -e -x -u

pushd nokogiri

  bundle install --local || bundle install
  bundle exec rake rubocop

popd
