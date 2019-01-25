#! /usr/bin/env bash

set -e -x -u

VERSION_INFO=$(ruby -v)
RUBY_ENGINE=$(cut -d" " -f1 <<< "${VERSION_INFO}")
RUBY_VERSION=$(cut -d" " -f2 <<< "${VERSION_INFO}")

FROZEN_STRING_REF="53f9b66"

function mri-24-or-greater {
  if [[ $RUBY_ENGINE != "ruby" ]] ; then
    return 1
  fi

  if echo $RUBY_VERSION | grep "^[0-2]\.[0-3]\." > /dev/null ; then
    return 1
  fi

  return 0
}

function commit-is-post-frozen-string-support {
  if git merge-base --is-ancestor ${FROZEN_STRING_REF} HEAD ; then
    return 0
  fi
  return 1
}

pushd nokogiri

  test_task="test"

  bundle install --local || bundle install
  bundle exec rake generate # do this before setting frozen string option, because racc isn't compatible with frozen string literals yet

  if mri-24-or-greater && commit-is-post-frozen-string-support ; then
    export RUBYOPT="--enable-frozen-string-literal --debug=frozen-string-literal"
  fi

  if [[ ${TEST_WITH_VALGRIND:-} != "" ]] ; then
    test_task="test:valgrind" # override
    # export TESTOPTS="-v" # see more verbose output to help narrow down warnings

    # always use the CI suppressions if they exist
    if [[ -d ../ci/suppressions ]] ; then
      rm -rf suppressions
      cp -var ../ci/suppressions .
    fi
  fi

  bundle exec rake compile ${test_task}

popd
