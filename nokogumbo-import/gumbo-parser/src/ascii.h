#ifndef GUMBO_ASCII_H_
#define GUMBO_ASCII_H_

#include <stddef.h>
#include "macros.h"

#ifdef __cplusplus
extern "C" {
#endif

#define gumbo_ascii_isupper(c) (((unsigned)(c) - 'A') < 26)

CONST_FN
static inline int gumbo_ascii_tolower(int c) {
    if (gumbo_ascii_isupper(c)) {
        return c | 32;
    }
    return c;
}

PURE NONNULL_ARGS
int gumbo_ascii_strcasecmp(const char *s1, const char *s2);

PURE NONNULL_ARGS
int gumbo_ascii_strncasecmp(const char *s1, const char *s2, size_t n);

#ifdef __cplusplus
}
#endif

#endif // GUMBO_ASCII_H_
