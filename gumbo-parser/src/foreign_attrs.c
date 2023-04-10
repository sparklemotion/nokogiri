/* ANSI-C code produced by gperf version 3.1 */
/* Command-line: gperf -m100 -n src/foreign_attrs.gperf  */
/* Computed positions: -k'8-9' */
/* Filtered by: gperf-filter.sed */

#include "replacement.h"
#include "macros.h"
#include <string.h>

#define TOTAL_KEYWORDS 11
#define MIN_WORD_LENGTH 5
#define MAX_WORD_LENGTH 13
#define MIN_HASH_VALUE 0
#define MAX_HASH_VALUE 10
/* maximum key range = 11, duplicates = 0 */

static inline unsigned int
hash (register const char *str, register size_t len)
{
  static const unsigned char asso_values[] =
    {
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11,  2,
      11,  1, 11, 10,  4,  4, 11, 11,  3, 11,
      11,  5,  3, 11,  0, 11,  2, 11, 11, 11,
      11,  2, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11
    };
  register unsigned int hval = 0;

  switch (len)
    {
      default:
        hval += asso_values[(unsigned char)str[8]];
      /*FALLTHROUGH*/
      case 8:
        hval += asso_values[(unsigned char)str[7]];
      /*FALLTHROUGH*/
      case 7:
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
       5, 10, 13,  9, 13, 10, 11, 11, 10, 10,  8
    };
  static const ForeignAttrReplacement wordlist[] =
    {
      {"xmlns", "xmlns", GUMBO_ATTR_NAMESPACE_XMLNS},
      {"xlink:href", "href", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xlink:arcrole", "arcrole", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xml:space", "space", GUMBO_ATTR_NAMESPACE_XML},
      {"xlink:actuate", "actuate", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xlink:type", "type", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xlink:title", "title", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xmlns:xlink", "xlink", GUMBO_ATTR_NAMESPACE_XMLNS},
      {"xlink:role", "role", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xlink:show", "show", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xml:lang", "lang", GUMBO_ATTR_NAMESPACE_XML}
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
