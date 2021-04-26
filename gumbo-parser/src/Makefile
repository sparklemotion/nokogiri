# this Makefile is used by ext/nokogiri/extconf.rb
# to enable a mini_portile2 recipe to build the gumbo parser
.PHONY: clean

override CFLAGS += -std=c99 -Wall

gumbo_objs := $(patsubst %.c,%.o,$(wildcard *.c))

libgumbo.a: $(gumbo_objs)
	ar rcs $@ $^

clean:
	rm -f $(gumbo_objs) libgumbo.a
