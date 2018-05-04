#ifndef GUMBO_UTIL_H_
#define GUMBO_UTIL_H_

#ifdef _MSC_VER
#define _CRT_SECURE_NO_WARNINGS
#endif

#include <stdbool.h>
#include <stddef.h>
#include "macros.h"

#ifdef __cplusplus
extern "C" {
#endif

// Forward declaration since it's passed into some of the functions in this
// header.
struct GumboInternalParser;

// Utility function for allocating & copying a null-terminated string into a
// freshly-allocated buffer. This is necessary for proper memory management; we
// have the convention that all const char* in parse tree structures are
// freshly-allocated, so if we didn't copy, we'd try to delete a literal string
// when the parse tree is destroyed.
char* gumbo_copy_stringz (
  struct GumboInternalParser* parser,
  const char* str
) MALLOC NONNULL_ARGS RETURNS_NONNULL;

// Allocate a chunk of memory
void* gumbo_parser_allocate (
  struct GumboInternalParser* parser,
  size_t num_bytes
) MALLOC RETURNS_NONNULL;

// Deallocate a chunk of memory
void gumbo_parser_deallocate(struct GumboInternalParser* parser, void* ptr);

// Debug wrapper for printf
void gumbo_debug(const char* format, ...) PRINTF(1);

int gumbo_ascii_strcasecmp(const char *s1, const char *s2) NONNULL_ARGS;
int gumbo_ascii_strncasecmp(const char *s1, const char *s2, size_t n) NONNULL_ARGS;

static inline char CONST_FN gumbo_ascii_tolower(char ch) {
    return 'A' <= ch && ch <= 'Z' ? ch | 0x20 : ch;
}

#ifdef __cplusplus
}
#endif

#endif // GUMBO_UTIL_H_
