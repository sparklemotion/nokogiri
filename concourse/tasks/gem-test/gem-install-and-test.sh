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

  if [ -n "${BUNDLE_APP_CONFIG:-}" ] ; then
    export BUNDLE_CACHE_PATH="${BUNDLE_APP_CONFIG}/cache"
  fi

  bundle install --local || bundle install # ensure dependencies are installed

  rm -rf lib ext # ensure we don't use the local files
  rake test

  if [[ -e ./scripts/test-gem-installation ]] ; then
    ./scripts/test-gem-installation
  fi

  if [[ -e ./scripts/test-nokogumbo-compatibility ]] ; then
    ./scripts/test-nokogumbo-compatibility
  fi

popd
