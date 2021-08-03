# this Makefile is used by ext/nokogiri/extconf.rb
# to enable a mini_portile2 recipe to build the gumbo parser
.PHONY: clean

CFLAGS += -std=c99 -Wall

# allow the ENV var to override this
RANLIB ?= ranlib

gumbo_objs := \
	ascii.o \
	attribute.o \
	char_ref.o \
	error.o \
	foreign_attrs.o \
	parser.o \
	string_buffer.o \
	string_piece.o \
	svg_attrs.o \
	svg_tags.o \
	tag.o \
	tag_lookup.o \
	token_buffer.o \
	tokenizer.o \
	utf8.o \
	util.o \
	vector.o

libgumbo.a: $(gumbo_objs)
	$(AR) $(ARFLAGS) $@ $(gumbo_objs)
	- ($(RANLIB) $@ || true) >/dev/null 2>&1

clean:
	rm -f $(gumbo_objs) libgumbo.a
