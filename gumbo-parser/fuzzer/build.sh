#!/usr/bin/env bash

set -eu

cd $(dirname $0)

echo $PWD

if [ ! -d gumbo_corpus ]; then
  unzip gumbo_corpus.zip -d gumbo_corpus
fi

SANITIZER_OPTS=""
SANITIZER_LINK=""
SANITIZER=${SANITIZER:-normal}

if [[ -z "${LLVM_CONFIG:-}" ]] ; then
  if [[ -x "$(command -v llvm-config)" ]]; then
    LLVM_CONFIG=$(which llvm-config)
  else
    echo 'llvm-config could not be found and $LLVM_CONFIG has not been set, expecting "export LLVM_CONFIG=/usr/bin/llvm-config-12" assuming clang-12 is installed, however any clang version works'
    exit
  fi
fi

mkdir -p build
srcdir=src-${SANITIZER}

CC="$($LLVM_CONFIG --bindir)/clang"
CXX="$($LLVM_CONFIG --bindir)/clang++"
CXXFLAGS="-fsanitize=fuzzer-no-link"
CFLAGS="-fsanitize=fuzzer-no-link"
ENGINE_LINK="$(find $($LLVM_CONFIG --libdir) -name libclang_rt.fuzzer-x86_64.a | head -1)"

if [[ "${SANITIZER}" = "ubsan" ]] ; then
  SANITIZER_OPTS="-fsanitize=undefined"
  SANITIZER_LINK="$(find $($LLVM_CONFIG --libdir) -name libclang_rt.ubsan_standalone_cxx-x86_64.a | head -1)"
fi
if [[ "${SANITIZER}" = "asan" ]] ; then
  SANITIZER_OPTS="-fsanitize=address"
  SANITIZER_LINK="$(find $($LLVM_CONFIG --libdir) -name libclang_rt.asan_cxx-x86_64.a | head -1)"
fi
if [[ "${SANITIZER}" = "msan" ]] ; then
  SANITIZER_OPTS="-fsanitize=memory -fPIE -pie -Wno-unused-command-line-argument"
  SANITIZER_LINK="$(find $($LLVM_CONFIG --libdir) -name libclang_rt.msan_cxx-x86_64.a | head -1)"
fi

CXXFLAGS="-O3 -g $CXXFLAGS $SANITIZER_OPTS"
CFLAGS="-O3 -g $CFLAGS $SANITIZER_OPTS"

export CC CFLAGS CXX CXXFLAGS

rm -rf $srcdir
cp -ar ../src $srcdir
pushd $srcdir
make
popd

if [[ "${SANITIZER}" = "normal" ]] ; then
  $CXX $CXXFLAGS -o build/parse_fuzzer parse_fuzzer.cc $srcdir/libgumbo.a $ENGINE_LINK $SANITIZER_LINK
else
  $CXX $CXXFLAGS -o build/parse_fuzzer-$SANITIZER parse_fuzzer.cc $srcdir/libgumbo.a $ENGINE_LINK $SANITIZER_LINK
fi
