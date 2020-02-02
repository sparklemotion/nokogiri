#! /usr/bin/env bash

set -e -x -u

pushd nokogiri

  OUTPUT_DIR="../gems"

  # inputs from a real git resource will contain this dir, but we may
  # run this task via `fly execute` and so we need to do this to avoid
  # cleanup, see extconf.rb do_clean
  mkdir -p .git

  export BUNDLE_GEMFILE="$(pwd)/Gemfile"
  bundle install --local || bundle install

  # TODO we're only compiling so that we retrieve libxml2/libxslt
  # tarballs, we can do better a couple of different ways
  bundle exec rake clean compile

  # generate a fake version number
  cp -f ../ci/tasks/set-version-to-timestamp.rb tasks/set-version-to-timestamp.rb
  bundle exec rake -f tasks/set-version-to-timestamp.rb set-version-to-timestamp

  bundle exec rake gem

  mkdir -p ${OUTPUT_DIR}
  cp -v pkg/nokogiri*.gem ${OUTPUT_DIR}
  sha256sum ${OUTPUT_DIR}/*

popd
