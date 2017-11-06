#ifndef GUMBO_UTIL_H_
#define GUMBO_UTIL_H_

#ifdef _MSC_VER
#define _CRT_SECURE_NO_WARNINGS
#endif

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Forward declaration since it's passed into some of the functions in this
// header.
struct GumboInternalParser;

// Utility function for allocating & copying a null-terminated string into a
// freshly-allocated buffer.  This is necessary for proper memory management; we
// have the convention that all const char* in parse tree structures are
// freshly-allocated, so if we didn't copy, we'd try to delete a literal string
// when the parse tree is destroyed.
char* gumbo_copy_stringz(struct GumboInternalParser* parser, const char* str);

// Allocate a chunk of memory, using the allocator specified in the Parser's
// config options.
void* gumbo_parser_allocate (
  struct GumboInternalParser* parser,
  size_t num_bytes
);

// Deallocate a chunk of memory, using the deallocator specified in the Parser's
// config options.
void gumbo_parser_deallocate(struct GumboInternalParser* parser, void* ptr);

// Debug wrapper for printf, to make it easier to turn off debugging info when
// required.
void gumbo_debug(const char* format, ...);

int gumbo_ascii_strcasecmp(const char *s1, const char *s2);
int gumbo_ascii_strncasecmp(const char *s1, const char *s2, size_t n);

static inline char gumbo_ascii_tolower(char ch) {
    return 'A' <= ch && ch <= 'Z' ? ch | 0x20 : ch;
}

#ifdef __cplusplus
}
#endif

#endif // GUMBO_UTIL_H_
