.PHONY: all clean check dirs

gumbo_objs := $(patsubst %.c,build/%.o,$(wildcard src/*.c))
test_objs := $(patsubst %.cc,build/%.o,$(wildcard test/*.cc))
gtest_lib := googletest/make/gtest_main.a

# make SANITIZEFLAGS='-fsanitize=undefined -fsanitize=address'
SANITIZEFLAGS :=
CPPFLAGS := -Isrc
CFLAGS := -std=c99 -Os
CXXFLAGS := -isystem googletest/include -std=c++11 -Os
LDFLAGS := -pthread

all: check

build/src:
	mkdir -p "$@"

build/test:
	mkdir -p "$@"

build/src/%.o: src/%.c | build/src
	$(CC) -MMD $(CPPFLAGS) $(CFLAGS) $(SANITIZEFLAGS) -c -o $@ $<

build/test/%.o: test/%.cc | build/test
	$(CXX) -MMD $(CPPFLAGS) $(CXXFLAGS) $(SANITIZEFLAGS) -c -o $@ $<

build/run_tests: $(gumbo_objs) $(test_objs) $(gtest_lib)
	$(CXX) -o $@ $+ $(LDFLAGS) $(SANITIZEFLAGS)

check: build/run_tests
	./build/run_tests

clean:
	$(RM) -r build

-include $(test_objs:.o=.d) $(gumbo_objs:.o=.d)
