#! /usr/bin/env bash

set -e -x -u

pushd nokogiri

  OUTPUT_DIR="../gems"

  # inputs from a real git resource will contain this dir, but we may
  # run this task via `fly execute` and so we need to do this to avoid
  # cleanup, see extconf.rb do_clean
  mkdir -p .git

  bundle install --local || bundle install

  bundle exec rake java gem

  mkdir -p ${OUTPUT_DIR}
  cp -v pkg/nokogiri*java.gem ${OUTPUT_DIR}
  sha256sum ${OUTPUT_DIR}/*

popd
