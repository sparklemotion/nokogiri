# this Makefile is used by ext/nokogiri/extconf.rb
# to enable a mini_portile2 recipe to build the gumbo parser
.PHONY: clean

override CFLAGS += -std=c99 -Wall

# allow the ENV var to override this
RANLIB ?= ranlib

gumbo_objs := $(patsubst %.c,%.o,$(wildcard *.c))

libgumbo.a: $(gumbo_objs)
	$(AR) $(ARFLAGS) $@ $^
	- ($(RANLIB) $@ || true) >/dev/null 2>&1

clean:
	rm -f $(gumbo_objs) libgumbo.a
