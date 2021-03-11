#! /usr/bin/env bash

test -e /etc/os-release && cat /etc/os-release

set -e -x -u

source "$(dirname "$0")/../../shared/code-climate.sh"

VERSION_INFO=$(ruby -v)
RUBY_ENGINE=$(cut -d" " -f1 <<< "${VERSION_INFO}")
RUBY_VERSION=$(cut -d" " -f2 <<< "${VERSION_INFO}")

pushd nokogiri

  bundle install --local || bundle install

  if [[ "${TEST_WITH_SYSTEM_LIBRARIES:-}" == "t" ]] ; then
    # TODO remove this option, prefer COMPILE_FLAGS instead
    export NOKOGIRI_USE_SYSTEM_LIBRARIES=t
  fi

  compile_task_args=""
  if [[ "${COMPILE_FLAGS:-}" != "" ]] ; then
    compile_task_args="-- ${COMPILE_FLAGS}"
  fi

  test_task="test"
  if [[ "${TEST_WITH_VALGRIND:-}" == "t" ]] ; then
    test_task="test:valgrind" # override
    # export TESTOPTS="-v" # see more verbose output to help narrow down warnings

    # always use the CI suppressions if they exist
    if [[ -d ../ci/suppressions ]] ; then
      rm -rf suppressions
      cp -var ../ci/suppressions .
    fi
  fi

  code-climate-setup

  bundle exec rake compile ${compile_task_args}
  bundle exec rake ${test_task}

  code-climate-shipit

popd
