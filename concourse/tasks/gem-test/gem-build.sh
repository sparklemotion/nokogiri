#! /usr/bin/env bash

if [ -n "${BUILD_NATIVE_GEM:-}" ] ; then
  # normally part of rake-compiler-dock runas
  . /etc/rubybashrc
  ln -s /usr/local/rake-compiler "$HOME"/.rake-compiler
fi

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

if [ -n "${BUILD_NATIVE_GEM:-}" ] ; then
  bundle exec rake gem:x86_64-linux:guest
else
  # TODO we're only compiling so that we retrieve libxml2/libxslt
  # tarballs, we can do better a couple of different ways
  bundle exec rake clean compile

  bundle exec rake gem
fi

mkdir -p ${OUTPUT_DIR}
cp -v pkg/nokogiri*.gem ${OUTPUT_DIR}
sha256sum ${OUTPUT_DIR}/*
