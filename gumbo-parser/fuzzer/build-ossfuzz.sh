cd src
make
cd ../

$CXX $CXXFLAGS -o $OUT/parse_fuzzer fuzzer/parse_fuzzer.cc src/libgumbo.a $LIB_FUZZING_ENGINE
cp fuzzer/gumbo.dict $OUT/parse_fuzzer.dict
cp fuzzer/gumbo_corpus.zip $OUT/parse_fuzzer_seed_corpus.zip

