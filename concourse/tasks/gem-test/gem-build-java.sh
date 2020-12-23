#! /usr/bin/env bash

test -e /etc/os-release && cat /etc/os-release

cd nokogiri

set -e -x -u # after the `cd` because of rvm

OUTPUT_DIR="../gems"

# inputs from a real git resource will contain this dir, but we may
# run this task via `fly execute` and so we need to do this to avoid
# cleanup, see extconf.rb do_clean
mkdir -p .git

bundle install --local || bundle install

# generate a fake version number
bundle exec rake set-version-to-timestamp

bundle exec rake java gem

if [ -e ./scripts/test-gem-file-contents ] ; then
  ./scripts/test-gem-file-contents pkg/nokogiri*java.gem
fi

mkdir -p ${OUTPUT_DIR}
cp -v pkg/nokogiri*java.gem ${OUTPUT_DIR}
sha256sum ${OUTPUT_DIR}/*
