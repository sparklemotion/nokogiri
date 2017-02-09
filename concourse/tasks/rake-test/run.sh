#! /usr/bin/env bash

set -e -x

pushd nokogiri

  VERSION_INFO=$(ruby -v)
  RUBY_ENGINE=$(cut -d" " -f1 <<< "${VERSION_INFO}")
  RUBY_VERSION=$(cut -d" " -f2 <<< "${VERSION_INFO}")

  APT_UPDATED=false

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

  function rbx-engine {
    if [[ $RUBY_ENGINE == "rubinius" ]] ; then
      return 0
    fi
    return 1
  }

  function ensure-apt-update {
    if [[ $APT_UPDATED != "false" ]] ; then
      return
    fi

    apt-get update
    APT_UPDATED=true
  }

  if mri-24-or-greater && commit-is-post-frozen-string-support ; then
    export RUBYOPT="--enable-frozen-string-literal --debug=frozen-string-literal"
  fi

  if rbx-engine ; then
    ensure-apt-update
    apt-get install -y ca-certificates gcc pkg-config libxml2-dev libxslt-dev
  fi

  RAKE_TASK="test"

  if [[ $TEST_WITH_VALGRIND != "" ]] ; then
    RAKE_TASK="test:valgrind" # override
    ensure-apt-update
    apt-get install -y valgrind
  fi

  bundle install
  bundle exec rake ${RAKE_TASK}

popd
