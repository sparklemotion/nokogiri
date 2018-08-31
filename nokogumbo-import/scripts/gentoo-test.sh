#!/usr/bin/env bash
set -e
set -o pipefail
set -v

cleanup() {
	rm -f .dockerignore
	if [ -n "$image" ]; then
		docker rmi "$image"
	fi
}

cd "$(dirname "$0")/.."
if [ -e .dockerignore ]; then
	echo 'Found an existing .dockerignore; aborting' >&2
	exit 1
fi

# Cleanup .dockerignore on exit
trap cleanup EXIT

cat >.dockerignore <<EOF
.*
appveyor.yml
tags
tmp
vendor
EOF
docker build -t gentoo-build-test -f - . <<EOF
FROM stevecheckoway/gentoo-ruby
ADD --chown=user:user . /home/user
EOF
image=gentoo-build-test
if [ -n "$DEBUG_DOCKER" ]; then
	docker run --rm -it "$image"
else
	docker run --rm -a STDOUT -a STDERR "$image" scripts/ci-test.sh
fi
