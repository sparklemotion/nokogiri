#ifndef GUMBO_CHAR_REF_H_
#define GUMBO_CHAR_REF_H_

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

struct GumboInternalParser;
struct GumboInternalUtf8Iterator;

// Value that indicates no character was produced.
extern const int kGumboNoChar;

// Certain named character references generate two codepoints, not one, and so
// the gumbo_consume_char_ref subroutine needs to return this instead of an int.
// The first field will be kGumboNoChar if no character reference was found; the
// second field will be kGumboNoChar if that is the case or if the character
// reference returns only a single codepoint.
typedef struct {
  int first;
  int second;
} OneOrTwoCodepoints;

// Implements the "consume a character reference" section of the spec.
// This reads in characters from the input as necessary, and fills in a
// OneOrTwoCodepoints struct containing the characters read. It may add parse
// errors to the GumboParser's errors vector, if the spec calls for it. Pass a
// space for the "additional allowed char" when the spec says "with no
// additional allowed char". Returns false on parse error, true otherwise.
bool gumbo_consume_char_ref (
  struct GumboInternalParser* parser,
  struct GumboInternalUtf8Iterator* input,
  int additional_allowed_char,
  bool is_in_attribute,
  OneOrTwoCodepoints* output
);

#ifdef __cplusplus
}
#endif

#endif // GUMBO_CHAR_REF_H_
