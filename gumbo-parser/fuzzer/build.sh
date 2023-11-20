#!/usr/bin/env bash

set -eu

cd $(dirname $0)

export SANITIZER_OPTS=""
export SANITIZER_LINK=""

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

export CC="$($LLVM_CONFIG --bindir)/clang"
export CXX="$($LLVM_CONFIG --bindir)/clang++"
export CXXFLAGS="-fsanitize=fuzzer-no-link"
export CFLAGS="-fsanitize=fuzzer-no-link"
export ENGINE_LINK="$(find $($LLVM_CONFIG --libdir) -name libclang_rt.fuzzer-x86_64.a | head -1)"

if [[ "${SANITIZER:-}" = "undefined" ]] ; then
  export SANITIZER_OPTS="-fsanitize=undefined"
  export SANITIZER_LINK="$(find $($LLVM_CONFIG --libdir) -name libclang_rt.ubsan_standalone_cxx-x86_64.a | head -1)"
fi
if [[ "${SANITIZER:-}" = "address" ]] ; then
  export SANITIZER_OPTS="-fsanitize=address"
  export SANITIZER_LINK="$(find $($LLVM_CONFIG --libdir) -name libclang_rt.asan_cxx-x86_64.a | head -1)"
fi
if [[ "${SANITIZER:-}" = "memory" ]] ; then
  export SANITIZER_OPTS="-fsanitize=memory -fPIE -pie -Wno-unused-command-line-argument"
  export SANITIZER_LINK="$(find $($LLVM_CONFIG --libdir) -name libclang_rt.msan_cxx-x86_64.a | head -1)"
fi

export CXXFLAGS="-O3 $CXXFLAGS $SANITIZER_OPTS"
export CFLAGS="-O3 $CFLAGS $SANITIZER_OPTS"

rm -rf $srcdir
cp -ar ../src $srcdir
pushd $srcdir
make
popd

if [[ -z "${SANITIZER:-}" ]] ; then
  $CXX $CXXFLAGS -o build/parse_fuzzer parse_fuzzer.cc $srcdir/libgumbo.a $ENGINE_LINK $SANITIZER_LINK
else
  $CXX $CXXFLAGS -o build/parse_fuzzer-$SANITIZER parse_fuzzer.cc $srcdir/libgumbo.a $ENGINE_LINK $SANITIZER_LINK
fi
