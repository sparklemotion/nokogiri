/* ANSI-C code produced by gperf version 3.1 */
/* Command-line: gperf -m100 lib/foreign_attrs.gperf  */
/* Computed positions: -k'7' */
/* Filtered by: mk/gperf-filter.sed */

#include "replacement.h"
#include "macros.h"
#include <string.h>

#define TOTAL_KEYWORDS 11
#define MIN_WORD_LENGTH 5
#define MAX_WORD_LENGTH 13
#define MIN_HASH_VALUE 5
#define MAX_HASH_VALUE 17
/* maximum key range = 13, duplicates = 0 */

static inline unsigned int
hash (register const char *str, register size_t len)
{
  static const unsigned char asso_values[] =
    {
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18,  0, 18, 18,
      18, 18, 18, 18,  7, 18, 18, 18, 18, 18,
       0, 18, 18, 18,  6,  4,  0, 18, 18, 18,
       4, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
      18, 18, 18, 18, 18, 18
    };
  register unsigned int hval = len;

  switch (hval)
    {
      default:
        hval += asso_values[(unsigned char)str[6]];
      /*FALLTHROUGH*/
      case 6:
      case 5:
        break;
    }
  return hval;
}

const ForeignAttrReplacement *
gumbo_get_foreign_attr_replacement (register const char *str, register size_t len)
{
  static const unsigned char lengthtable[] =
    {
       0,  0,  0,  0,  0,  5,  0,  0,  8,  9, 10, 11,  8, 13,
      10, 11, 10, 10
    };
  static const ForeignAttrReplacement wordlist[] =
    {
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0},
      {"xmlns", "xmlns", GUMBO_ATTR_NAMESPACE_XMLNS},
      {(char*)0}, {(char*)0},
      {"xml:lang", "lang", GUMBO_ATTR_NAMESPACE_XML},
      {"xml:space", "space", GUMBO_ATTR_NAMESPACE_XML},
      {"xlink:type", "type", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xlink:title", "title", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xml:base", "base", GUMBO_ATTR_NAMESPACE_XML},
      {"xlink:actuate", "actuate", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xlink:show", "show", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xmlns:xlink", "xlink", GUMBO_ATTR_NAMESPACE_XMLNS},
      {"xlink:role", "role", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xlink:href", "href", GUMBO_ATTR_NAMESPACE_XLINK}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register unsigned int key = hash (str, len);

      if (key <= MAX_HASH_VALUE)
        if (len == lengthtable[key])
          {
            register const char *s = wordlist[key].from;

            if (s && *str == *s && !memcmp (str + 1, s + 1, len - 1))
              return &wordlist[key];
          }
    }
  return 0;
}
