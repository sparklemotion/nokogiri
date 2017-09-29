#ifndef GUMBO_TAG_LOOKUP_H_
#define GUMBO_TAG_LOOKUP_H_

#include "gumbo.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    const char *key;
    const GumboTag tag;
} TagHashSlot;

const TagHashSlot *gumbo_tag_lookup(const char *str, size_t len);

#ifdef __cplusplus
}
#endif

#endif // GUMBO_TAG_LOOKUP_H_
