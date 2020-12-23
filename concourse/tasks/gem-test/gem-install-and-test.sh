#! /usr/bin/env bash

test -e /etc/os-release && cat /etc/os-release

set -e -x -u

GEM_PACKAGING_REF=813d119
function commit-is-post-gem-packaging-cleanup {
  if git merge-base --is-ancestor ${GEM_PACKAGING_REF} HEAD ; then
    return 0
  fi
  return 1
}

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
  bundle -v
  bundle config

  bundle add nokogiri --skip-install
  bundle install --local || bundle install
  bundle info nokogiri

  bundle exec rake test:cmd > run-test
  rm -rf lib ext # ensure we can't use the local files
  bundle exec bash run-test

  if commit-is-post-gem-packaging-cleanup ; then
    if [[ -e ./scripts/test-gem-installation ]] ; then
      gem install minitest-reporters # TODO: remove once PRs based on pre-1e57386 have passed
      ./scripts/test-gem-installation
    fi
  fi
popd
