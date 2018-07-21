#ifndef GUMBO_ASCII_H_
#define GUMBO_ASCII_H_

#include <stddef.h>
#include "macros.h"

#ifdef __cplusplus
extern "C" {
#endif

PURE NONNULL_ARGS
int gumbo_ascii_strcasecmp(const char *s1, const char *s2);

PURE NONNULL_ARGS
int gumbo_ascii_strncasecmp(const char *s1, const char *s2, size_t n);

CONST_FN
static inline char gumbo_ascii_tolower(char ch) {
    return 'A' <= ch && ch <= 'Z' ? ch | 0x20 : ch;
}

#ifdef __cplusplus
}
#endif

#endif // GUMBO_ASCII_H_
