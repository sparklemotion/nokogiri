#!/usr/bin/env bash
set -e
set -o pipefail
set -v

if [ "$USE_SYSTEM_LIBRARIES" = true ]; then
	export NOKOGIRI_USE_SYSTEM_LIBRARIES=true
fi
bundle install --path vendor/bundle
MAKE='make -j2 V=1' bundle exec rake -- --without-libxml2
bundle exec rake clean
MAKE='make -j2 V=1' bundle exec rake -- --with-libxml2
