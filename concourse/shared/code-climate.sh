#
#  Source this file to have access to two functions:
#
#    code-climate-setup
#
#      * downloads the CC CLI
#      * sets up CC environment variables
#      * invokes CC's `before-build`
#
#
#    code-climate-shipit
#
#      * invokes CC's `after-build`
#
#  Note that the env var CC_TEST_REPORTER_ID will need to be set. You
#  can find this on your Code Climate project's "Repo Settings" page.
#

CC_CLI_URI="https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64"
CC_CLI=$(basename ${CC_CLI_URI})

function code-climate-setup {
  save-option-xtrace-off

  if [ -z "${CC_TEST_REPORTER_ID:-}" ] ; then
    echo "WARNING: code-climate-setup: CC_TEST_REPORTER_ID is not set, skipping."
  else
    wget --no-verbose ${CC_CLI_URI}
    chmod +x ${CC_CLI}

    export CI_NAME="concourse"

    ./${CC_CLI} env || true
    ./${CC_CLI} before-build || true
  fi

  restore-option-xtrace
}

function code-climate-shipit {
  save-option-xtrace-off

  if [ -z "${CC_TEST_REPORTER_ID:-}" ] ; then
    echo "WARNING: code-climate-shipit: CC_TEST_REPORTER_ID is not set, skipping."
  else
    ./${CC_CLI} after-build || true
  fi

  restore-option-xtrace
}


#
#  utilities to save and restore the `xtrace` setting so we don't leak credentials
#  https://unix.stackexchange.com/questions/310957/how-to-restore-the-value-of-shell-options-like-set-x/310963
#
OLD_OPTION_XTRACE=""

function save-option-xtrace {
  OLD_OPTION_XTRACE="$(shopt -po xtrace)"
  set +x
}

function save-option-xtrace-off {
  save-option-xtrace
  set +x
}

function restore-option-xtrace {
  set +vx # suppress the following eval statement
  eval "${OLD_OPTION_XTRACE}"
}
