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
  if [ -z "${CC_TEST_REPORTER_ID:-}" ] ; then
    echo "WARNING: code-climate-setup: CC_TEST_REPORTER_ID is not set, skipping."
    return
  fi

  wget --no-verbose ${CC_CLI_URI}
  chmod +x ${CC_CLI}

  export CI_NAME="concourse"

  ./${CC_CLI} env
  ./${CC_CLI} before-build
}

function code-climate-shipit {
  if [ -z "${CC_TEST_REPORTER_ID:-}" ] ; then
    echo "WARNING: code-climate-shipit: CC_TEST_REPORTER_ID is not set, skipping."
    return
  fi

  # let's remove the `|| true` once all pull requests from pre-simplecov are cleared out
  ./${CC_CLI} after-build || true
}
