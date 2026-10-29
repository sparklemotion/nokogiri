#
#  this script is run by oss-fuzz to build the fuzzer
#  see https://github.com/google/oss-fuzz/blob/master/projects/nokogiri/build.sh
#
set -ex

cd src
make
cd ../

for fuzzer in parse_fuzzer parse_options_fuzzer ; do
  $CXX $CXXFLAGS -o $OUT/$fuzzer fuzzer/$fuzzer.cc src/libgumbo.a $LIB_FUZZING_ENGINE
  cp fuzzer/gumbo.dict $OUT/$fuzzer.dict
  cp fuzzer/gumbo_corpus.zip $OUT/${fuzzer}_seed_corpus.zip
done
