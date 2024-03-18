#ifndef GUMBO_UTIL_H_
#define GUMBO_UTIL_H_

#include <stdbool.h>
#include <stddef.h>
#include "macros.h"

#define GUMBO_USE_ARENA 1

#ifdef __cplusplus
extern "C" {
#endif

// Utility function for allocating & copying a null-terminated string into a
// freshly-allocated buffer. This is necessary for proper memory management; we
// have the convention that all const char* in parse tree structures are
// freshly-allocated, so if we didn't copy, we'd try to delete a literal string
// when the parse tree is destroyed.
char* gumbo_strdup(const char* str) XMALLOC NONNULL_ARGS;

void* gumbo_alloc(size_t size) XMALLOC;
void* gumbo_realloc(void* prev_ptr, size_t prev_size, size_t size) RETURNS_NONNULL;

// Debug wrapper for printf
#ifdef GUMBO_DEBUG
void gumbo_debug(const char* format, ...) PRINTF(1);
#else
static inline void PRINTF(1) gumbo_debug(const char* UNUSED_ARG(format), ...) {};
#endif

#ifdef __cplusplus
}
#endif

#endif // GUMBO_UTIL_H_
