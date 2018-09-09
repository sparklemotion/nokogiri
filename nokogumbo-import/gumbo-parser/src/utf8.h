#ifndef GUMBO_UTF8_H_
#define GUMBO_UTF8_H_

// This contains an implementation of a UTF-8 iterator and decoder suitable for
// a HTML5 parser. This does a bit more than straight UTF-8 decoding. The
// HTML5 spec specifies that:
// 1. Decoding errors are parse errors.
// 2. Certain other codepoints (e.g. control characters) are parse errors.
// 3. Carriage returns and CR/LF groups are converted to line feeds.
// https://encoding.spec.whatwg.org/#utf-8-decode
//
// Also, we want to keep track of source positions for error handling. As a
// result, we fold all that functionality into this decoder, and can't use an
// off-the-shelf library.
//
// This header is internal-only, which is why we prefix functions with only
// utf8_ or utf8_iterator_ instead of gumbo_utf8_.

#include <stdbool.h>
#include <stddef.h>

#include "gumbo.h"
#include "macros.h"

#ifdef __cplusplus
extern "C" {
#endif

struct GumboInternalError;
struct GumboInternalParser;

// Unicode replacement char.
#define kUtf8ReplacementChar 0xFFFD
#define kUtf8MaxChar 0x10FFFF

typedef struct GumboInternalUtf8Iterator {
  // Points at the start of the code point most recently read into 'current'.
  const char* _start;

  // Points at the mark. The mark is initially set to the beginning of the
  // input.
  const char* _mark;

  // Points past the end of the iter, like a past-the-end iterator in the STL.
  const char* _end;

  // The code point under the cursor.
  int _current;

  // The width in bytes of the current code point.
  size_t _width;

  // The SourcePosition for the current location.
  GumboSourcePosition _pos;

  // The SourcePosition for the mark.
  GumboSourcePosition _mark_pos;

  // Pointer back to the GumboParser instance, for configuration options and
  // error recording.
  struct GumboInternalParser* _parser;
} Utf8Iterator;

// Returns true if this Unicode code point is in the list of characters
// forbidden by the HTML5 spec, such as NUL bytes and undefined control chars.
bool utf8_is_invalid_code_point(int c) CONST_FN;

// Returns true if this Unicode code point is a surrogate.
CONST_FN static inline bool utf8_is_surrogate(int c) {
  return c >= 0xD800 && c <= 0xDFFF;
}

// Returns true if this Unicode code point is a noncharacter.
CONST_FN static inline bool utf8_is_noncharacter(int c) {
  return
    (c >= 0xFDD0 && c <= 0xFDEF)
    || ((c & 0xFFFF) == 0xFFFE)
    || ((c & 0xFFFF) == 0xFFFF);
}

// Returns true if this Unicode code point is a control.
CONST_FN static inline bool utf8_is_control(int c) {
  return ((unsigned int)c < 0x1Fu) || (c >= 0x7F && c <= 0x9F);
}

// Initializes a new Utf8Iterator from the given byte buffer. The source does
// not have to be NUL-terminated, but the length must be passed in explicitly.
void utf8iterator_init (
  struct GumboInternalParser* parser,
  const char* source,
  size_t source_length,
  Utf8Iterator* iter
);

// Advances the current position by one code point.
void utf8iterator_next(Utf8Iterator* iter);

// Returns the current code point as an integer.
int utf8iterator_current(const Utf8Iterator* iter);

// Retrieves and fills the output parameter with the current source position.
void utf8iterator_get_position(
    const Utf8Iterator* iter, GumboSourcePosition* output);

// Retrieves a character pointer to the start of the current character.
const char* utf8iterator_get_char_pointer(const Utf8Iterator* iter);

// Retrieves a character pointer to 1 past the end of the buffer. This is
// necessary for certain state machines and string comparisons that would like
// to look directly for ASCII text in the buffer without going through the
// decoder.
const char* utf8iterator_get_end_pointer(const Utf8Iterator* iter);

// If the upcoming text in the buffer matches the specified prefix (which has
// length 'length'), consume it and return true. Otherwise, return false with
// no other effects. If the length of the string would overflow the buffer,
// this returns false. Note that prefix should not contain null bytes because
// of the use of strncmp/strncasecmp internally. All existing use-cases adhere
// to this.
bool utf8iterator_maybe_consume_match (
  Utf8Iterator* iter,
  const char* prefix,
  size_t length,
  bool case_sensitive
);

// "Marks" a particular location of interest in the input stream, so that it can
// later be reset() to. There's also the ability to record an error at the
// point that was marked, as oftentimes that's more useful than the last
// character before the error was detected.
void utf8iterator_mark(Utf8Iterator* iter);

// Returns the current input stream position to the mark.
void utf8iterator_reset(Utf8Iterator* iter);

// Sets the position and original text fields of an error to the value at the
// mark.
void utf8iterator_fill_error_at_mark (
  Utf8Iterator* iter,
  struct GumboInternalError* error
);

#ifdef __cplusplus
}
#endif

#endif // GUMBO_UTF8_H_
