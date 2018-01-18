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

#define TOTAL_KEYWORDS 151
#define MIN_WORD_LENGTH 1
#define MAX_WORD_LENGTH 14
#define MIN_HASH_VALUE 7
#define MAX_HASH_VALUE 285
/* maximum key range = 279, duplicates = 0 */

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
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286,   8,
        6,   5,   3,   3,   2,   3,   2,   2, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286,  52,  79, 148,
        6,  15,  53,  93,   4,  72,  55, 124,  11,  18,
       46,  68,  23, 111,   2,   3,   8,  45, 101, 113,
      105, 107, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286, 286,
      286, 286, 286, 286, 286, 286, 286, 286, 286
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
       0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  2,  2,  2,  2,
       6,  2,  6,  2,  4,  0,  7,  6,  3,  0,  3,  0,  6,  6,
       8,  5,  2,  0,  4,  5,  5,  8,  4,  0,  4,  5,  0,  0,
       5,  0,  0,  0,  7,  1,  8,  5,  3,  0,  5,  2,  4,  0,
       4,  2,  2,  8,  7,  7,  6,  6,  8,  0,  0,  4,  4,  6,
       6,  4,  8,  4,  4,  0, 13,  4,  4,  8,  8,  0,  0,  6,
       0,  6,  3,  2,  6,  0,  2,  1,  0,  5,  0,  0,  2,  6,
       2,  0,  0,  8,  8,  2,  4,  1,  0,  2,  9,  2,  0,  0,
       3,  0,  8,  5,  6,  0,  5,  7, 10,  3,  7,  6,  2,  2,
       2,  3,  2,  2,  7,  2,  4,  3,  3,  5,  5,  6,  2,  0,
       0,  0,  8,  5,  5,  1,  0,  7,  3,  2,  4,  0,  4,  4,
       3,  7,  3,  0, 10,  1,  6,  0,  4,  6,  3,  6,  0,  0,
       0,  4,  0,  0, 10,  5,  0,  0,  0,  2,  4,  0,  6,  8,
       5,  0,  0,  5,  3,  6, 14,  3,  3,  3,  4,  0,  0,  0,
       5,  0,  0,  0,  0,  0,  0,  0,  0,  0,  3,  7,  0,  0,
       0,  0,  0,  0,  0,  6,  0,  0,  4,  0,  0,  0,  7,  1,
       0,  0,  0,  0,  0,  0,  5,  0,  0,  0,  0,  0,  6,  0,
       0,  0,  0,  0,  0,  3,  0,  0,  0,  3,  0,  0,  0,  0,
       0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
       3,  0,  0,  0,  0,  0,  0,  0,  0,  0,  5,  0,  0,  0,
       0,  0,  0,  0,  0,  7
    };
  static const TagHashSlot wordlist[] =
    {
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0},
      {"s", GUMBO_TAG_S},
      {(char*)0}, {(char*)0},
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
      {"rp", GUMBO_TAG_RP},
      {(char*)0},
      {"math", GUMBO_TAG_MATH},
      {"label", GUMBO_TAG_LABEL},
      {"table", GUMBO_TAG_TABLE},
      {"template", GUMBO_TAG_TEMPLATE},
      {"samp", GUMBO_TAG_SAMP},
      {(char*)0},
      {"time", GUMBO_TAG_TIME},
      {"title", GUMBO_TAG_TITLE},
      {(char*)0}, {(char*)0},
      {"small", GUMBO_TAG_SMALL},
      {(char*)0}, {(char*)0}, {(char*)0},
      {"marquee", GUMBO_TAG_MARQUEE},
      {"p", GUMBO_TAG_P},
      {"menuitem", GUMBO_TAG_MENUITEM},
      {"embed", GUMBO_TAG_EMBED},
      {"map", GUMBO_TAG_MAP},
      {(char*)0},
      {"param", GUMBO_TAG_PARAM},
      {"hr", GUMBO_TAG_HR},
      {"nobr", GUMBO_TAG_NOBR},
      {(char*)0},
      {"span", GUMBO_TAG_SPAN},
      {"tr", GUMBO_TAG_TR},
      {"em", GUMBO_TAG_EM},
      {"noframes", GUMBO_TAG_NOFRAMES},
      {"section", GUMBO_TAG_SECTION},
      {"noembed", GUMBO_TAG_NOEMBED},
      {"nextid", GUMBO_TAG_NEXTID},
      {"footer", GUMBO_TAG_FOOTER},
      {"noscript", GUMBO_TAG_NOSCRIPT},
      {(char*)0}, {(char*)0},
      {"font", GUMBO_TAG_FONT},
      {"data", GUMBO_TAG_DATA},
      {"applet", GUMBO_TAG_APPLET},
      {"script", GUMBO_TAG_SCRIPT},
      {"menu", GUMBO_TAG_MENU},
      {"textarea", GUMBO_TAG_TEXTAREA},
      {"abbr", GUMBO_TAG_ABBR},
      {"main", GUMBO_TAG_MAIN},
      {(char*)0},
      {"foreignobject", GUMBO_TAG_FOREIGNOBJECT},
      {"form", GUMBO_TAG_FORM},
      {"meta", GUMBO_TAG_META},
      {"progress", GUMBO_TAG_PROGRESS},
      {"fieldset", GUMBO_TAG_FIELDSET},
      {(char*)0}, {(char*)0},
      {"mglyph", GUMBO_TAG_MGLYPH},
      {(char*)0},
      {"figure", GUMBO_TAG_FIGURE},
      {"pre", GUMBO_TAG_PRE},
      {"dl", GUMBO_TAG_DL},
      {"hgroup", GUMBO_TAG_HGROUP},
      {(char*)0},
      {"mo", GUMBO_TAG_MO},
      {"u", GUMBO_TAG_U},
      {(char*)0},
      {"tfoot", GUMBO_TAG_TFOOT},
      {(char*)0}, {(char*)0},
      {"li", GUMBO_TAG_LI},
      {"object", GUMBO_TAG_OBJECT},
      {"rb", GUMBO_TAG_RB},
      {(char*)0}, {(char*)0},
      {"basefont", GUMBO_TAG_BASEFONT},
      {"optgroup", GUMBO_TAG_OPTGROUP},
      {"mi", GUMBO_TAG_MI},
      {"base", GUMBO_TAG_BASE},
      {"a", GUMBO_TAG_A},
      {(char*)0},
      {"dd", GUMBO_TAG_DD},
      {"plaintext", GUMBO_TAG_PLAINTEXT},
      {"td", GUMBO_TAG_TD},
      {(char*)0}, {(char*)0},
      {"var", GUMBO_TAG_VAR},
      {(char*)0},
      {"frameset", GUMBO_TAG_FRAMESET},
      {"image", GUMBO_TAG_IMAGE},
      {"dialog", GUMBO_TAG_DIALOG},
      {(char*)0},
      {"frame", GUMBO_TAG_FRAME},
      {"article", GUMBO_TAG_ARTICLE},
      {"figcaption", GUMBO_TAG_FIGCAPTION},
      {"div", GUMBO_TAG_DIV},
      {"listing", GUMBO_TAG_LISTING},
      {"option", GUMBO_TAG_OPTION},
      {"ms", GUMBO_TAG_MS},
      {"rt", GUMBO_TAG_RT},
      {"ul", GUMBO_TAG_UL},
      {"dfn", GUMBO_TAG_DFN},
      {"br", GUMBO_TAG_BR},
      {"dt", GUMBO_TAG_DT},
      {"acronym", GUMBO_TAG_ACRONYM},
      {"tt", GUMBO_TAG_TT},
      {"html", GUMBO_TAG_HTML},
      {"wbr", GUMBO_TAG_WBR},
      {"sup", GUMBO_TAG_SUP},
      {"tbody", GUMBO_TAG_TBODY},
      {"style", GUMBO_TAG_STYLE},
      {"strike", GUMBO_TAG_STRIKE},
      {"th", GUMBO_TAG_TH},
      {(char*)0}, {(char*)0}, {(char*)0},
      {"multicol", GUMBO_TAG_MULTICOL},
      {"thead", GUMBO_TAG_THEAD},
      {"mtext", GUMBO_TAG_MTEXT},
      {"i", GUMBO_TAG_I},
      {(char*)0},
      {"bgsound", GUMBO_TAG_BGSOUND},
      {"kbd", GUMBO_TAG_KBD},
      {"ol", GUMBO_TAG_OL},
      {"link", GUMBO_TAG_LINK},
      {(char*)0},
      {"mark", GUMBO_TAG_MARK},
      {"area", GUMBO_TAG_AREA},
      {"xmp", GUMBO_TAG_XMP},
      {"address", GUMBO_TAG_ADDRESS},
      {"nav", GUMBO_TAG_NAV},
      {(char*)0},
      {"malignmark", GUMBO_TAG_MALIGNMARK},
      {"b", GUMBO_TAG_B},
      {"center", GUMBO_TAG_CENTER},
      {(char*)0},
      {"desc", GUMBO_TAG_DESC},
      {"canvas", GUMBO_TAG_CANVAS},
      {"col", GUMBO_TAG_COL},
      {"iframe", GUMBO_TAG_IFRAME},
      {(char*)0}, {(char*)0}, {(char*)0},
      {"code", GUMBO_TAG_CODE},
      {(char*)0}, {(char*)0},
      {"blockquote", GUMBO_TAG_BLOCKQUOTE},
      {"aside", GUMBO_TAG_ASIDE},
      {(char*)0}, {(char*)0}, {(char*)0},
      {"mn", GUMBO_TAG_MN},
      {"cite", GUMBO_TAG_CITE},
      {(char*)0},
      {"keygen", GUMBO_TAG_KEYGEN},
      {"colgroup", GUMBO_TAG_COLGROUP},
      {"track", GUMBO_TAG_TRACK},
      {(char*)0}, {(char*)0},
      {"video", GUMBO_TAG_VIDEO},
      {"big", GUMBO_TAG_BIG},
      {"output", GUMBO_TAG_OUTPUT},
      {"annotation-xml", GUMBO_TAG_ANNOTATION_XML},
      {"ins", GUMBO_TAG_INS},
      {"sub", GUMBO_TAG_SUB},
      {"img", GUMBO_TAG_IMG},
      {"body", GUMBO_TAG_BODY},
      {(char*)0}, {(char*)0}, {(char*)0},
      {"input", GUMBO_TAG_INPUT},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0},
      {"svg", GUMBO_TAG_SVG},
      {"caption", GUMBO_TAG_CAPTION},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0},
      {"strong", GUMBO_TAG_STRONG},
      {(char*)0}, {(char*)0},
      {"ruby", GUMBO_TAG_RUBY},
      {(char*)0}, {(char*)0}, {(char*)0},
      {"summary", GUMBO_TAG_SUMMARY},
      {"q", GUMBO_TAG_Q},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0},
      {"audio", GUMBO_TAG_AUDIO},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0},
      {"button", GUMBO_TAG_BUTTON},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0},
      {"bdo", GUMBO_TAG_BDO},
      {(char*)0}, {(char*)0}, {(char*)0},
      {"bdi", GUMBO_TAG_BDI},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0},
      {"rtc", GUMBO_TAG_RTC},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0},
      {"blink", GUMBO_TAG_BLINK},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {(char*)0}, {(char*)0}, {(char*)0}, {(char*)0},
      {"isindex", GUMBO_TAG_ISINDEX}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register unsigned int key = hash (str, len);

      if (key <= MAX_HASH_VALUE)
        if (len == lengthtable[key])
          {
            register const char *s = wordlist[key].key;

            if (s && *str == *s && !memcmp (str + 1, s + 1, len - 1))
              return &wordlist[key];
          }
    }
  return 0;
}
