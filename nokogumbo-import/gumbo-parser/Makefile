.PHONY: all clean check dirs

gumbo_objs := $(patsubst %.c,build/%.o,$(wildcard src/*.c))
test_objs := $(patsubst %.cc,build/%.o,$(wildcard test/*.cc))
gtest_lib := googletest/make/gtest_main.a

# make SANITIZEFLAGS='-fsanitize=undefined -fsanitize=address'
SANITIZEFLAGS :=
CPPFLAGS := -Isrc
CFLAGS := -std=c99 -Os -Wall
CXXFLAGS := -isystem googletest/include -std=c++11 -Os -Wall
LDFLAGS := -pthread

all: check

src/%.c: src/%.rl
	ragel -F1 -o $@ $<

build/src:
	mkdir -p $@

build/test:
	mkdir -p $@

build/src/%.o: src/%.c build/src/flags | build/src
	$(CC) -MMD $(CPPFLAGS) $(CFLAGS) $(SANITIZEFLAGS) -c -o $@ $<

build/test/%.o: test/%.cc build/test/flags | build/test
	$(CXX) -MMD $(CPPFLAGS) $(CXXFLAGS) $(SANITIZEFLAGS) -c -o $@ $<

build/run_tests: $(gumbo_objs) $(test_objs) $(gtest_lib)
	$(CXX) -o $@ $+ $(LDFLAGS) $(SANITIZEFLAGS)

check: build/run_tests
	./build/run_tests

clean:
	$(RM) -r build

build/src/flags: | build/src
	@echo 'old_CC := $(CC)' > $@
	@echo 'old_CPPFLAGS := $(CPPFLAGS)' >> $@
	@echo 'old_CFLAGS := $(CFLAGS)' >>$@
	@echo 'old_SANITIZEFLAGS := $(SANITIZEFLAGS)' >> $@
	@echo 'old_LDFLAGS := $(LDFLAGS)' >> $@

build/test/flags: | build/test
	@echo 'old_CXX := $(CXX)' > $@
	@echo 'old_CPPFLAGS := $(CPPFLAGS)' >> $@
	@echo 'old_CXXFLAGS := $(CXXFLAGS)' >> $@
	@echo 'old_SANITIZEFLAGS := $(SANITIZEFLAGS)' >> $@
	@echo 'old_LDFLAGS := $(LDFLAGS)' >> $@

ifneq ($(MAKECMDGOALS),clean)
# Ensure that the flags are up to date.
-include build/src/flags build/test/flags
ifneq ($(old_CC) | $(old_CPPFLAGS) | $(old_CFLAGS) | $(old_SANITIZEFLAGS) | $(old_LDFLAGS),$(CC) | $(CPPFLAGS) | $(CFLAGS) | $(SANITIZEFLAGS) | $(LDFLAGS))
.PHONY: build/src/flags
endif
ifneq ($(old_CXX) | $(old_CPPFLAGS) | $(old_CXXFLAGS) | $(old_SANITIZEFLAGS) | $(old_LDFLAGS),$(CXX) | $(CPPFLAGS) | $(CXXFLAGS) | $(SANITIZEFLAGS) | $(LDFLAGS))
.PHONY: build/test/flags
endif

# Include dependencies.
-include $(test_objs:.o=.d) $(gumbo_objs:.o=.d)
endif
