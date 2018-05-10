/* ANSI-C code produced by gperf version 3.1 */
/* Command-line: gperf -m100 lib/tag_lookup.gperf  */
/* Computed positions: -k'1-2,$' */

#if !((' ' == 32) && ('!' == 33) && ('"' == 34) && ('#' == 35) \
      && ('%' == 37) && ('&' == 38) && ('\'' == 39) && ('(' == 40) \
      && (')' == 41) && ('*' == 42) && ('+' == 43) && (',' == 44) \
      && ('-' == 45) && ('.' == 46) && ('/' == 47) && ('0' == 48) \
      && ('1' == 49) && ('2' == 50) && ('3' == 51) && ('4' == 52) \
      && ('5' == 53) && ('6' == 54) && ('7' == 55) && ('8' == 56) \
      && ('9' == 57) && (':' == 58) && (';' == 59) && ('<' == 60) \
      && ('=' == 61) && ('>' == 62) && ('?' == 63) && ('A' == 65) \
      && ('B' == 66) && ('C' == 67) && ('D' == 68) && ('E' == 69) \
      && ('F' == 70) && ('G' == 71) && ('H' == 72) && ('I' == 73) \
      && ('J' == 74) && ('K' == 75) && ('L' == 76) && ('M' == 77) \
      && ('N' == 78) && ('O' == 79) && ('P' == 80) && ('Q' == 81) \
      && ('R' == 82) && ('S' == 83) && ('T' == 84) && ('U' == 85) \
      && ('V' == 86) && ('W' == 87) && ('X' == 88) && ('Y' == 89) \
      && ('Z' == 90) && ('[' == 91) && ('\\' == 92) && (']' == 93) \
      && ('^' == 94) && ('_' == 95) && ('a' == 97) && ('b' == 98) \
      && ('c' == 99) && ('d' == 100) && ('e' == 101) && ('f' == 102) \
      && ('g' == 103) && ('h' == 104) && ('i' == 105) && ('j' == 106) \
      && ('k' == 107) && ('l' == 108) && ('m' == 109) && ('n' == 110) \
      && ('o' == 111) && ('p' == 112) && ('q' == 113) && ('r' == 114) \
      && ('s' == 115) && ('t' == 116) && ('u' == 117) && ('v' == 118) \
      && ('w' == 119) && ('x' == 120) && ('y' == 121) && ('z' == 122) \
      && ('{' == 123) && ('|' == 124) && ('}' == 125) && ('~' == 126))
/* The character set is not based on ISO-646.  */
#error "gperf generated tables don't work with this execution character set. Please report a bug to <bug-gperf@gnu.org>."
#endif


#include "tag_lookup.h"
#include <string.h>

#define TOTAL_KEYWORDS 150
#define MIN_WORD_LENGTH 1
#define MAX_WORD_LENGTH 14
#define MIN_HASH_VALUE 9
#define MAX_HASH_VALUE 271
/* maximum key range = 263, duplicates = 0 */

#ifndef GPERF_DOWNCASE
#define GPERF_DOWNCASE 1
static unsigned char gperf_downcase[256] =
  {
      0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,
     15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  28,  29,
     30,  31,  32,  33,  34,  35,  36,  37,  38,  39,  40,  41,  42,  43,  44,
     45,  46,  47,  48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,
     60,  61,  62,  63,  64,  97,  98,  99, 100, 101, 102, 103, 104, 105, 106,
    107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121,
    122,  91,  92,  93,  94,  95,  96,  97,  98,  99, 100, 101, 102, 103, 104,
    105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119,
    120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134,
    135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149,
    150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164,
    165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179,
    180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194,
    195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209,
    210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224,
    225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239,
    240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254,
    255
  };
#endif

#ifndef GPERF_CASE_MEMCMP
#define GPERF_CASE_MEMCMP 1
static int
gperf_case_memcmp (register const char *s1, register const char *s2, register size_t n)
{
  for (; n > 0;)
    {
      unsigned char c1 = gperf_downcase[(unsigned char)*s1++];
      unsigned char c2 = gperf_downcase[(unsigned char)*s2++];
      if (c1 == c2)
        {
          n--;
          continue;
        }
      return (int)c1 - (int)c2;
    }
  return 0;
}
#endif

#ifdef __GNUC__
__inline
#else
#ifdef __cplusplus
inline
#endif
#endif
static unsigned int
hash (register const char *str, register size_t len)
{
  static const unsigned short asso_values[] =
    {
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272,   9,
        7,   6,   4,   4,   3,   4,   3,   3, 272, 272,
      272, 272, 272, 272, 272,  70,  83, 152,   7,  16,
       61,  98,   5,  76, 102, 126,  12,  19,  54,  54,
       31,  97,   3,   4,   9,  33, 136, 113,  86,  15,
      272, 272, 272, 272, 272, 272, 272,  70,  83, 152,
        7,  16,  61,  98,   5,  76, 102, 126,  12,  19,
       54,  54,  31,  97,   3,   4,   9,  33, 136, 113,
       86,  15, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272, 272,
      272, 272, 272, 272, 272, 272, 272, 272, 272
    };
  register unsigned int hval = len;

  switch (hval)
    {
      default:
        hval += asso_values[(unsigned char)str[1]+3];
      /*FALLTHROUGH*/
      case 1:
        hval += asso_values[(unsigned char)str[0]];
        break;
    }
  return hval + asso_values[(unsigned char)str[len - 1]];
}

const TagHashSlot *
gumbo_tag_lookup (register const char *str, register size_t len)
{
  static const unsigned char lengthtable[] =
    {
       0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  2,
       2,  2,  2,  6,  2,  6,  2,  4,  0,  7,  6,  3,  0,  3,
       0,  6,  6,  8,  5,  0,  0,  4,  5,  5,  8,  0,  2,  4,
       5,  2,  0,  5,  4,  2,  0,  7,  0,  8,  5,  0,  0,  0,
       0,  0,  0,  5,  3,  4,  5,  1,  4,  0,  4,  1,  2,  8,
       7,  7,  6,  6,  8,  2,  8,  4,  2,  0,  6,  0,  0,  3,
       4,  6, 13,  4,  4,  6,  8,  0,  8,  4,  0,  6,  0,  8,
       4,  5,  0,  2,  2,  9,  2,  4,  0,  8,  4,  2,  4,  8,
       7,  0,  2,  5,  2,  0,  6,  0,  3,  2,  2,  6,  3,  8,
       7,  2,  5,  7,  0,  2,  6,  2,  4,  3,  0, 10,  5,  6,
       3,  1,  2,  0,  6,  0,  5,  5,  0,  3,  0,  3,  3,  1,
       4,  6,  4,  7,  3,  0,  0,  2, 10, 10,  0,  0,  6,  1,
       4,  6,  3,  0,  2,  5,  6,  4,  3,  4,  0,  7,  3,  0,
       0,  0,  4,  0,  0,  5,  0,  0,  0,  6,  0, 14,  8,  1,
       3,  0,  0,  7,  3,  0,  0,  0,  0,  0,  0,  5,  3,  0,
       0,  0,  0,  0,  0,  5,  0,  0,  0,  0,  7,  6,  0,  0,
       0,  0,  0,  5,  0,  6,  0,  0,  0,  0,  0,  0,  0,  0,
       3,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
       0,  0,  0,  0,  0,  0,  0,  0,  3,  0,  0,  0,  0,  0,
       0,  0,  5,  0,  0,  3
    };
  static const TagHashSlot wordlist[] =
    {
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0},
      {"s", GUMBO_TAG_S},
      {(char*)0}, {(char*)0}, {(char*)0},
      {"h6", GUMBO_TAG_H6},
      {"h5", GUMBO_TAG_H5},
      {"h4", GUMBO_TAG_H4},
      {"h3", GUMBO_TAG_H3},
      {"spacer", GUMBO_TAG_SPACER},
      {"h2", GUMBO_TAG_H2},
      {"header", GUMBO_TAG_HEADER},
      {"h1", GUMBO_TAG_H1},
      {"head", GUMBO_TAG_HEAD},
      {(char*)0},
      {"details", GUMBO_TAG_DETAILS},
      {"select", GUMBO_TAG_SELECT},
      {"dir", GUMBO_TAG_DIR},
      {(char*)0},
      {"del", GUMBO_TAG_DEL},
      {(char*)0},
      {"source", GUMBO_TAG_SOURCE},
      {"legend", GUMBO_TAG_LEGEND},
      {"datalist", GUMBO_TAG_DATALIST},
      {"meter", GUMBO_TAG_METER},
      {(char*)0}, {(char*)0},
      {"math", GUMBO_TAG_MATH},
      {"label", GUMBO_TAG_LABEL},
      {"table", GUMBO_TAG_TABLE},
      {"template", GUMBO_TAG_TEMPLATE},
      {(char*)0},
      {"rp", GUMBO_TAG_RP},
      {"time", GUMBO_TAG_TIME},
      {"title", GUMBO_TAG_TITLE},
      {"hr", GUMBO_TAG_HR},
      {(char*)0},
      {"tbody", GUMBO_TAG_TBODY},
      {"samp", GUMBO_TAG_SAMP},
      {"tr", GUMBO_TAG_TR},
      {(char*)0},
      {"marquee", GUMBO_TAG_MARQUEE},
      {(char*)0},
      {"menuitem", GUMBO_TAG_MENUITEM},
      {"small", GUMBO_TAG_SMALL},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0},
      {"embed", GUMBO_TAG_EMBED},
      {"map", GUMBO_TAG_MAP},
      {"menu", GUMBO_TAG_MENU},
      {"param", GUMBO_TAG_PARAM},
      {"p", GUMBO_TAG_P},
      {"nobr", GUMBO_TAG_NOBR},
      {(char*)0},
      {"span", GUMBO_TAG_SPAN},
      {"u", GUMBO_TAG_U},
      {"em", GUMBO_TAG_EM},
      {"noframes", GUMBO_TAG_NOFRAMES},
      {"section", GUMBO_TAG_SECTION},
      {"noembed", GUMBO_TAG_NOEMBED},
      {"nextid", GUMBO_TAG_NEXTID},
      {"footer", GUMBO_TAG_FOOTER},
      {"noscript", GUMBO_TAG_NOSCRIPT},
      {"dl", GUMBO_TAG_DL},
      {"progress", GUMBO_TAG_PROGRESS},
      {"font", GUMBO_TAG_FONT},
      {"mo", GUMBO_TAG_MO},
      {(char*)0},
      {"script", GUMBO_TAG_SCRIPT},
      {(char*)0}, {(char*)0},
      {"pre", GUMBO_TAG_PRE},
      {"main", GUMBO_TAG_MAIN},
      {"object", GUMBO_TAG_OBJECT},
      {"foreignobject", GUMBO_TAG_FOREIGNOBJECT},
      {"form", GUMBO_TAG_FORM},
      {"data", GUMBO_TAG_DATA},
      {"applet", GUMBO_TAG_APPLET},
      {"fieldset", GUMBO_TAG_FIELDSET},
      {(char*)0},
      {"textarea", GUMBO_TAG_TEXTAREA},
      {"abbr", GUMBO_TAG_ABBR},
      {(char*)0},
      {"figure", GUMBO_TAG_FIGURE},
      {(char*)0},
      {"optgroup", GUMBO_TAG_OPTGROUP},
      {"meta", GUMBO_TAG_META},
      {"tfoot", GUMBO_TAG_TFOOT},
      {(char*)0},
      {"ul", GUMBO_TAG_UL},
      {"li", GUMBO_TAG_LI},
      {"plaintext", GUMBO_TAG_PLAINTEXT},
      {"rb", GUMBO_TAG_RB},
      {"body", GUMBO_TAG_BODY},
      {(char*)0},
      {"basefont", GUMBO_TAG_BASEFONT},
      {"ruby", GUMBO_TAG_RUBY},
      {"mi", GUMBO_TAG_MI},
      {"base", GUMBO_TAG_BASE},
      {"frameset", GUMBO_TAG_FRAMESET},
      {"summary", GUMBO_TAG_SUMMARY},
      {(char*)0},
      {"dd", GUMBO_TAG_DD},
      {"frame", GUMBO_TAG_FRAME},
      {"td", GUMBO_TAG_TD},
      {(char*)0},
      {"option", GUMBO_TAG_OPTION},
      {(char*)0},
      {"svg", GUMBO_TAG_SVG},
      {"br", GUMBO_TAG_BR},
      {"ol", GUMBO_TAG_OL},
      {"dialog", GUMBO_TAG_DIALOG},
      {"sup", GUMBO_TAG_SUP},
      {"multicol", GUMBO_TAG_MULTICOL},
      {"article", GUMBO_TAG_ARTICLE},
      {"rt", GUMBO_TAG_RT},
      {"image", GUMBO_TAG_IMAGE},
      {"listing", GUMBO_TAG_LISTING},
      {(char*)0},
      {"dt", GUMBO_TAG_DT},
      {"mglyph", GUMBO_TAG_MGLYPH},
      {"tt", GUMBO_TAG_TT},
      {"html", GUMBO_TAG_HTML},
      {"wbr", GUMBO_TAG_WBR},
      {(char*)0},
      {"figcaption", GUMBO_TAG_FIGCAPTION},
      {"style", GUMBO_TAG_STYLE},
      {"strike", GUMBO_TAG_STRIKE},
      {"dfn", GUMBO_TAG_DFN},
      {"a", GUMBO_TAG_A},
      {"th", GUMBO_TAG_TH},
      {(char*)0},
      {"hgroup", GUMBO_TAG_HGROUP},
      {(char*)0},
      {"mtext", GUMBO_TAG_MTEXT},
      {"thead", GUMBO_TAG_THEAD},
      {(char*)0},
      {"var", GUMBO_TAG_VAR},
      {(char*)0},
      {"xmp", GUMBO_TAG_XMP},
      {"kbd", GUMBO_TAG_KBD},
      {"i", GUMBO_TAG_I},
      {"link", GUMBO_TAG_LINK},
      {"output", GUMBO_TAG_OUTPUT},
      {"mark", GUMBO_TAG_MARK},
      {"acronym", GUMBO_TAG_ACRONYM},
      {"div", GUMBO_TAG_DIV},
      {(char*)0}, {(char*)0},
      {"ms", GUMBO_TAG_MS},
      {"malignmark", GUMBO_TAG_MALIGNMARK},
      {"blockquote", GUMBO_TAG_BLOCKQUOTE},
      {(char*)0}, {(char*)0},
      {"center", GUMBO_TAG_CENTER},
      {"b", GUMBO_TAG_B},
      {"desc", GUMBO_TAG_DESC},
      {"canvas", GUMBO_TAG_CANVAS},
      {"col", GUMBO_TAG_COL},
      {(char*)0},
      {"mn", GUMBO_TAG_MN},
      {"track", GUMBO_TAG_TRACK},
      {"iframe", GUMBO_TAG_IFRAME},
      {"code", GUMBO_TAG_CODE},
      {"sub", GUMBO_TAG_SUB},
      {"area", GUMBO_TAG_AREA},
      {(char*)0},
      {"address", GUMBO_TAG_ADDRESS},
      {"ins", GUMBO_TAG_INS},
      {(char*)0}, {(char*)0}, {(char*)0},
      {"cite", GUMBO_TAG_CITE},
      {(char*)0}, {(char*)0},
      {"input", GUMBO_TAG_INPUT},
      {(char*)0}, {(char*)0}, {(char*)0},
      {"keygen", GUMBO_TAG_KEYGEN},
      {(char*)0},
      {"annotation-xml", GUMBO_TAG_ANNOTATION_XML},
      {"colgroup", GUMBO_TAG_COLGROUP},
      {"q", GUMBO_TAG_Q},
      {"big", GUMBO_TAG_BIG},
      {(char*)0}, {(char*)0},
      {"bgsound", GUMBO_TAG_BGSOUND},
      {"nav", GUMBO_TAG_NAV},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0},
      {"video", GUMBO_TAG_VIDEO},
      {"img", GUMBO_TAG_IMG},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0},
      {"audio", GUMBO_TAG_AUDIO},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {"caption", GUMBO_TAG_CAPTION},
      {"strong", GUMBO_TAG_STRONG},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0},
      {"aside", GUMBO_TAG_ASIDE},
      {(char*)0},
      {"button", GUMBO_TAG_BUTTON},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {"bdo", GUMBO_TAG_BDO},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0},
      {"bdi", GUMBO_TAG_BDI},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0},
      {"blink", GUMBO_TAG_BLINK},
      {(char*)0}, {(char*)0},
      {"rtc", GUMBO_TAG_RTC}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register unsigned int key = hash (str, len);

      if (key <= MAX_HASH_VALUE)
        if (len == lengthtable[key])
          {
            register const char *s = wordlist[key].key;

            if (s && (((unsigned char)*str ^ (unsigned char)*s) & ~32) == 0 && !gperf_case_memcmp (str, s, len))
              return &wordlist[key];
          }
    }
  return 0;
}
