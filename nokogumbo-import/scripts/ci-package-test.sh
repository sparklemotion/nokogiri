#!/usr/bin/env bash
set -e
set -o pipefail
set -v

assert_equal() {
	if [ "$1" != "$2" ]; then
		echo 'Failed'
		echo "Expected: $1"
		echo "Actual: $2"
		exit 1
	fi
}

expected='<!DOCTYPE html><html><head></head><body><span>Working!</span></body></html>'

bundle install --path vendor/bundle

if [ "$NO_GUMBO_TESTS" != true ]; then
	curl -L https://github.com/google/googletest/archive/release-1.8.0.tar.gz | \
	  tar zxf - --strip-components 1 -C gumbo-parser googletest-release-1.8.0/googletest
	make -C gumbo-parser/googletest/make gtest_main.a

	bundle exec rake test:gumbo
fi
bundle exec rake gem

gem install -i /tmp/without pkg/nokogumbo-*.gem -- --without-libxml2
actual="$(GEM_PATH=/tmp/without ruby -rnokogumbo \
	-e 'puts Nokogiri::HTML5("<!DOCTYPE html><span>Working!</span>").serialize')"
assert_equal "$expected" "$actual"

gem install -i /tmp/with pkg/nokogumbo-*.gem -- --with-libxml2
actual="$(GEM_PATH=/tmp/with ruby -rnokogumbo \
	-e 'puts Nokogiri::HTML5("<!DOCTYPE html><span>Working!</span>").serialize')"
assert_equal "$expected" "$actual"
