#! /usr/bin/env bash

cd nokogiri

set -e -x -u

OUTPUT_DIR="../gems"

# inputs from a real git resource will contain this dir, but we may
# run this task via `fly execute` and so we need to do this to avoid
# cleanup, see extconf.rb do_clean
mkdir -p .git

export BUNDLE_GEMFILE="$(pwd)/Gemfile"
bundle install --local || bundle install

# generate a fake version number
cp -f ../ci/tasks/set-version-to-timestamp.rb tasks/set-version-to-timestamp.rb
bundle exec rake -f tasks/set-version-to-timestamp.rb set-version-to-timestamp

bundle exec rake java gem

mkdir -p ${OUTPUT_DIR}
cp -v pkg/nokogiri*java.gem ${OUTPUT_DIR}
sha256sum ${OUTPUT_DIR}/*
