#ifndef GUMBO_STRING_BUFFER_H_
#define GUMBO_STRING_BUFFER_H_

#include <stdbool.h>
#include <stddef.h>

#include "gumbo.h"

struct GumboInternalParser;

// A struct representing a mutable, growable string.  This consists of a
// heap-allocated buffer that may grow (by doubling) as necessary.  When
// converting to a string, this allocates a new buffer that is only as long as
// it needs to be.  Note that the internal buffer here is *not* nul-terminated,
// so be sure not to use ordinary string manipulation functions on it.
typedef struct {
  // A pointer to the beginning of the string.  NULL iff length == 0.
  char* data;

  // The length of the string fragment, in bytes.  May be zero.
  size_t length;

  // The capacity of the buffer, in bytes.
  size_t capacity;
} GumboStringBuffer;

// Initializes a new GumboStringBuffer.
void gumbo_string_buffer_init (
  struct GumboInternalParser* parser,
  GumboStringBuffer* output
);

// Ensures that the buffer contains at least a certain amount of space.  Most
// useful with snprintf and the other length-delimited string functions, which
// may want to write directly into the buffer.
void gumbo_string_buffer_reserve (
  struct GumboInternalParser* parser,
  size_t min_capacity,
  GumboStringBuffer* output
);

// Appends a single Unicode codepoint onto the end of the GumboStringBuffer.
// This is essentially a UTF-8 encoder, and may add 1-4 bytes depending on the
// value of the codepoint.
void gumbo_string_buffer_append_codepoint (
  struct GumboInternalParser* parser,
  int c,
  GumboStringBuffer* output
);

// Appends a string onto the end of the GumboStringBuffer.
void gumbo_string_buffer_append_string(
  struct GumboInternalParser* parser,
  GumboStringPiece* str,
  GumboStringBuffer* output
);

// Converts this string buffer to const char*, alloctaing a new buffer for it.
char* gumbo_string_buffer_to_string (
  struct GumboInternalParser* parser,
  GumboStringBuffer* input
);

// Reinitialize this string buffer.  This clears it by setting length=0.  It
// does not zero out the buffer itself.
void gumbo_string_buffer_clear (
  struct GumboInternalParser* parser,
  GumboStringBuffer* input
);

// Deallocates this GumboStringBuffer.
void gumbo_string_buffer_destroy (
  struct GumboInternalParser* parser,
  GumboStringBuffer* buffer
);

#endif // GUMBO_STRING_BUFFER_H_
