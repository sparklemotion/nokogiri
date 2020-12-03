#! /usr/bin/env bash

test -e /etc/os-release && cat /etc/os-release

if [ -n "${BUILD_NATIVE_GEM:-}" ] ; then
  # normally part of rake-compiler-dock runas which we can't easily use in concourse
  . /etc/rubybashrc
  ln -s /usr/local/rake-compiler "$HOME"/.rake-compiler
fi

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

if [ -n "${BUILD_NATIVE_GEM:-}" ] ; then
  bundle exec rake gem:x86_64-linux:builder FORCE_CROSS_COMPILING=true
else
  # TODO we're only compiling so that we retrieve libxml2/libxslt
  # tarballs, we can do better a couple of different ways
  bundle exec rake clean compile

  bundle exec rake gem
fi

mkdir -p ${OUTPUT_DIR}
cp -v pkg/nokogiri*.gem ${OUTPUT_DIR}
sha256sum ${OUTPUT_DIR}/*
