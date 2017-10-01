#ifndef GUMBO_STRING_PIECE_H_
#define GUMBO_STRING_PIECE_H_

#include "gumbo.h"

#ifdef __cplusplus
extern "C" {
#endif

struct GumboInternalParser;

// Performs a deep-copy of an GumboStringPiece, allocating a fresh buffer in the
// destination and copying over the characters from source.  Dest should be
// empty, with no buffer allocated; otherwise, this leaks it.
void gumbo_string_copy (
  struct GumboInternalParser* parser,
  GumboStringPiece* dest,
  const GumboStringPiece* source
);

#ifdef __cplusplus
}
#endif

#endif // GUMBO_STRING_PIECE_H_
