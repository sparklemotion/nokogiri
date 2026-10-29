#
#  this script is run by oss-fuzz to build the fuzzer
#  see https://github.com/google/oss-fuzz/blob/master/projects/nokogiri/build.sh
#
set -ex

cd src
make
cd ../

$CXX $CXXFLAGS -o $OUT/parse_fuzzer fuzzer/parse_fuzzer.cc src/libgumbo.a $LIB_FUZZING_ENGINE
cp fuzzer/gumbo.dict $OUT/parse_fuzzer.dict
cp fuzzer/gumbo_corpus.zip $OUT/parse_fuzzer_seed_corpus.zip

$CXX $CXXFLAGS -o $OUT/error_report_fuzzer fuzzer/error_report_fuzzer.cc src/libgumbo.a $LIB_FUZZING_ENGINE
cp fuzzer/gumbo.dict $OUT/error_report_fuzzer.dict
zip -j $OUT/error_report_fuzzer_seed_corpus.zip fuzzer/corpus/error_report/*
