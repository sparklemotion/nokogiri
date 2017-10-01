#ifndef GUMBO_ATTRIBUTE_H_
#define GUMBO_ATTRIBUTE_H_

#include "gumbo.h"

#ifdef __cplusplus
extern "C" {
#endif

struct GumboInternalParser;

// Release the memory used for a GumboAttribute, including the attribute itself
void gumbo_destroy_attribute (
  struct GumboInternalParser* parser,
  GumboAttribute* attribute
);

#ifdef __cplusplus
}
#endif

#endif // GUMBO_ATTRIBUTE_H_
