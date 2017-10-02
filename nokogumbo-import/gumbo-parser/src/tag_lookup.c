/* ANSI-C code produced by gperf version 3.1 */
/* Command-line: gperf -LANSI-C -m200 lib/tag_lookup.gperf  */
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

#line 1 "lib/tag_lookup.gperf"

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
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
#line 58 "lib/tag_lookup.gperf"
      {"s", GUMBO_TAG_S},
      {""}, {""},
#line 35 "lib/tag_lookup.gperf"
      {"h6", GUMBO_TAG_H6},
#line 34 "lib/tag_lookup.gperf"
      {"h5", GUMBO_TAG_H5},
#line 33 "lib/tag_lookup.gperf"
      {"h4", GUMBO_TAG_H4},
#line 32 "lib/tag_lookup.gperf"
      {"h3", GUMBO_TAG_H3},
#line 162 "lib/tag_lookup.gperf"
      {"spacer", GUMBO_TAG_SPACER},
#line 31 "lib/tag_lookup.gperf"
      {"h2", GUMBO_TAG_H2},
#line 37 "lib/tag_lookup.gperf"
      {"header", GUMBO_TAG_HEADER},
#line 30 "lib/tag_lookup.gperf"
      {"h1", GUMBO_TAG_H1},
#line 16 "lib/tag_lookup.gperf"
      {"head", GUMBO_TAG_HEAD},
      {""},
#line 135 "lib/tag_lookup.gperf"
      {"details", GUMBO_TAG_DETAILS},
#line 126 "lib/tag_lookup.gperf"
      {"select", GUMBO_TAG_SELECT},
#line 142 "lib/tag_lookup.gperf"
      {"dir", GUMBO_TAG_DIR},
      {""},
#line 84 "lib/tag_lookup.gperf"
      {"del", GUMBO_TAG_DEL},
      {""},
#line 93 "lib/tag_lookup.gperf"
      {"source", GUMBO_TAG_SOURCE},
#line 122 "lib/tag_lookup.gperf"
      {"legend", GUMBO_TAG_LEGEND},
#line 127 "lib/tag_lookup.gperf"
      {"datalist", GUMBO_TAG_DATALIST},
#line 134 "lib/tag_lookup.gperf"
      {"meter", GUMBO_TAG_METER},
#line 77 "lib/tag_lookup.gperf"
      {"rp", GUMBO_TAG_RP},
      {""},
#line 98 "lib/tag_lookup.gperf"
      {"math", GUMBO_TAG_MATH},
#line 123 "lib/tag_lookup.gperf"
      {"label", GUMBO_TAG_LABEL},
#line 110 "lib/tag_lookup.gperf"
      {"table", GUMBO_TAG_TABLE},
#line 24 "lib/tag_lookup.gperf"
      {"template", GUMBO_TAG_TEMPLATE},
#line 67 "lib/tag_lookup.gperf"
      {"samp", GUMBO_TAG_SAMP},
      {""},
#line 64 "lib/tag_lookup.gperf"
      {"time", GUMBO_TAG_TIME},
#line 17 "lib/tag_lookup.gperf"
      {"title", GUMBO_TAG_TITLE},
      {""}, {""},
#line 57 "lib/tag_lookup.gperf"
      {"small", GUMBO_TAG_SMALL},
      {""}, {""}, {""},
#line 159 "lib/tag_lookup.gperf"
      {"marquee", GUMBO_TAG_MARQUEE},
#line 40 "lib/tag_lookup.gperf"
      {"p", GUMBO_TAG_P},
#line 138 "lib/tag_lookup.gperf"
      {"menuitem", GUMBO_TAG_MENUITEM},
#line 88 "lib/tag_lookup.gperf"
      {"embed", GUMBO_TAG_EMBED},
#line 96 "lib/tag_lookup.gperf"
      {"map", GUMBO_TAG_MAP},
      {""},
#line 90 "lib/tag_lookup.gperf"
      {"param", GUMBO_TAG_PARAM},
#line 41 "lib/tag_lookup.gperf"
      {"hr", GUMBO_TAG_HR},
#line 161 "lib/tag_lookup.gperf"
      {"nobr", GUMBO_TAG_NOBR},
      {""},
#line 80 "lib/tag_lookup.gperf"
      {"span", GUMBO_TAG_SPAN},
#line 117 "lib/tag_lookup.gperf"
      {"tr", GUMBO_TAG_TR},
#line 55 "lib/tag_lookup.gperf"
      {"em", GUMBO_TAG_EM},
#line 145 "lib/tag_lookup.gperf"
      {"noframes", GUMBO_TAG_NOFRAMES},
#line 27 "lib/tag_lookup.gperf"
      {"section", GUMBO_TAG_SECTION},
#line 150 "lib/tag_lookup.gperf"
      {"noembed", GUMBO_TAG_NOEMBED},
#line 149 "lib/tag_lookup.gperf"
      {"nextid", GUMBO_TAG_NEXTID},
#line 38 "lib/tag_lookup.gperf"
      {"footer", GUMBO_TAG_FOOTER},
#line 23 "lib/tag_lookup.gperf"
      {"noscript", GUMBO_TAG_NOSCRIPT},
      {""}, {""},
#line 158 "lib/tag_lookup.gperf"
      {"font", GUMBO_TAG_FONT},
#line 63 "lib/tag_lookup.gperf"
      {"data", GUMBO_TAG_DATA},
#line 139 "lib/tag_lookup.gperf"
      {"applet", GUMBO_TAG_APPLET},
#line 22 "lib/tag_lookup.gperf"
      {"script", GUMBO_TAG_SCRIPT},
#line 137 "lib/tag_lookup.gperf"
      {"menu", GUMBO_TAG_MENU},
#line 130 "lib/tag_lookup.gperf"
      {"textarea", GUMBO_TAG_TEXTAREA},
#line 62 "lib/tag_lookup.gperf"
      {"abbr", GUMBO_TAG_ABBR},
#line 52 "lib/tag_lookup.gperf"
      {"main", GUMBO_TAG_MAIN},
      {""},
#line 108 "lib/tag_lookup.gperf"
      {"foreignobject", GUMBO_TAG_FOREIGNOBJECT},
#line 120 "lib/tag_lookup.gperf"
      {"form", GUMBO_TAG_FORM},
#line 20 "lib/tag_lookup.gperf"
      {"meta", GUMBO_TAG_META},
#line 133 "lib/tag_lookup.gperf"
      {"progress", GUMBO_TAG_PROGRESS},
#line 121 "lib/tag_lookup.gperf"
      {"fieldset", GUMBO_TAG_FIELDSET},
      {""}, {""},
#line 104 "lib/tag_lookup.gperf"
      {"mglyph", GUMBO_TAG_MGLYPH},
      {""},
#line 50 "lib/tag_lookup.gperf"
      {"figure", GUMBO_TAG_FIGURE},
#line 42 "lib/tag_lookup.gperf"
      {"pre", GUMBO_TAG_PRE},
#line 47 "lib/tag_lookup.gperf"
      {"dl", GUMBO_TAG_DL},
#line 36 "lib/tag_lookup.gperf"
      {"hgroup", GUMBO_TAG_HGROUP},
      {""},
#line 100 "lib/tag_lookup.gperf"
      {"mo", GUMBO_TAG_MO},
#line 73 "lib/tag_lookup.gperf"
      {"u", GUMBO_TAG_U},
      {""},
#line 116 "lib/tag_lookup.gperf"
      {"tfoot", GUMBO_TAG_TFOOT},
      {""}, {""},
#line 46 "lib/tag_lookup.gperf"
      {"li", GUMBO_TAG_LI},
#line 89 "lib/tag_lookup.gperf"
      {"object", GUMBO_TAG_OBJECT},
#line 152 "lib/tag_lookup.gperf"
      {"rb", GUMBO_TAG_RB},
      {""}, {""},
#line 154 "lib/tag_lookup.gperf"
      {"basefont", GUMBO_TAG_BASEFONT},
#line 128 "lib/tag_lookup.gperf"
      {"optgroup", GUMBO_TAG_OPTGROUP},
#line 99 "lib/tag_lookup.gperf"
      {"mi", GUMBO_TAG_MI},
#line 18 "lib/tag_lookup.gperf"
      {"base", GUMBO_TAG_BASE},
#line 54 "lib/tag_lookup.gperf"
      {"a", GUMBO_TAG_A},
      {""},
#line 49 "lib/tag_lookup.gperf"
      {"dd", GUMBO_TAG_DD},
#line 151 "lib/tag_lookup.gperf"
      {"plaintext", GUMBO_TAG_PLAINTEXT},
#line 118 "lib/tag_lookup.gperf"
      {"td", GUMBO_TAG_TD},
      {""}, {""},
#line 66 "lib/tag_lookup.gperf"
      {"var", GUMBO_TAG_VAR},
      {""},
#line 144 "lib/tag_lookup.gperf"
      {"frameset", GUMBO_TAG_FRAMESET},
#line 85 "lib/tag_lookup.gperf"
      {"image", GUMBO_TAG_IMAGE},
#line 165 "lib/tag_lookup.gperf"
      {"dialog", GUMBO_TAG_DIALOG},
      {""},
#line 143 "lib/tag_lookup.gperf"
      {"frame", GUMBO_TAG_FRAME},
#line 26 "lib/tag_lookup.gperf"
      {"article", GUMBO_TAG_ARTICLE},
#line 51 "lib/tag_lookup.gperf"
      {"figcaption", GUMBO_TAG_FIGCAPTION},
#line 53 "lib/tag_lookup.gperf"
      {"div", GUMBO_TAG_DIV},
#line 147 "lib/tag_lookup.gperf"
      {"listing", GUMBO_TAG_LISTING},
#line 129 "lib/tag_lookup.gperf"
      {"option", GUMBO_TAG_OPTION},
#line 102 "lib/tag_lookup.gperf"
      {"ms", GUMBO_TAG_MS},
#line 76 "lib/tag_lookup.gperf"
      {"rt", GUMBO_TAG_RT},
#line 45 "lib/tag_lookup.gperf"
      {"ul", GUMBO_TAG_UL},
#line 61 "lib/tag_lookup.gperf"
      {"dfn", GUMBO_TAG_DFN},
#line 81 "lib/tag_lookup.gperf"
      {"br", GUMBO_TAG_BR},
#line 48 "lib/tag_lookup.gperf"
      {"dt", GUMBO_TAG_DT},
#line 140 "lib/tag_lookup.gperf"
      {"acronym", GUMBO_TAG_ACRONYM},
#line 163 "lib/tag_lookup.gperf"
      {"tt", GUMBO_TAG_TT},
#line 15 "lib/tag_lookup.gperf"
      {"html", GUMBO_TAG_HTML},
#line 82 "lib/tag_lookup.gperf"
      {"wbr", GUMBO_TAG_WBR},
#line 70 "lib/tag_lookup.gperf"
      {"sup", GUMBO_TAG_SUP},
#line 114 "lib/tag_lookup.gperf"
      {"tbody", GUMBO_TAG_TBODY},
#line 21 "lib/tag_lookup.gperf"
      {"style", GUMBO_TAG_STYLE},
#line 153 "lib/tag_lookup.gperf"
      {"strike", GUMBO_TAG_STRIKE},
#line 119 "lib/tag_lookup.gperf"
      {"th", GUMBO_TAG_TH},
      {""}, {""}, {""},
#line 160 "lib/tag_lookup.gperf"
      {"multicol", GUMBO_TAG_MULTICOL},
#line 115 "lib/tag_lookup.gperf"
      {"thead", GUMBO_TAG_THEAD},
#line 103 "lib/tag_lookup.gperf"
      {"mtext", GUMBO_TAG_MTEXT},
#line 71 "lib/tag_lookup.gperf"
      {"i", GUMBO_TAG_I},
      {""},
#line 141 "lib/tag_lookup.gperf"
      {"bgsound", GUMBO_TAG_BGSOUND},
#line 68 "lib/tag_lookup.gperf"
      {"kbd", GUMBO_TAG_KBD},
#line 44 "lib/tag_lookup.gperf"
      {"ol", GUMBO_TAG_OL},
#line 19 "lib/tag_lookup.gperf"
      {"link", GUMBO_TAG_LINK},
      {""},
#line 74 "lib/tag_lookup.gperf"
      {"mark", GUMBO_TAG_MARK},
#line 97 "lib/tag_lookup.gperf"
      {"area", GUMBO_TAG_AREA},
#line 148 "lib/tag_lookup.gperf"
      {"xmp", GUMBO_TAG_XMP},
#line 39 "lib/tag_lookup.gperf"
      {"address", GUMBO_TAG_ADDRESS},
#line 28 "lib/tag_lookup.gperf"
      {"nav", GUMBO_TAG_NAV},
      {""},
#line 105 "lib/tag_lookup.gperf"
      {"malignmark", GUMBO_TAG_MALIGNMARK},
#line 72 "lib/tag_lookup.gperf"
      {"b", GUMBO_TAG_B},
#line 157 "lib/tag_lookup.gperf"
      {"center", GUMBO_TAG_CENTER},
      {""},
#line 109 "lib/tag_lookup.gperf"
      {"desc", GUMBO_TAG_DESC},
#line 95 "lib/tag_lookup.gperf"
      {"canvas", GUMBO_TAG_CANVAS},
#line 113 "lib/tag_lookup.gperf"
      {"col", GUMBO_TAG_COL},
#line 87 "lib/tag_lookup.gperf"
      {"iframe", GUMBO_TAG_IFRAME},
      {""}, {""}, {""},
#line 65 "lib/tag_lookup.gperf"
      {"code", GUMBO_TAG_CODE},
      {""}, {""},
#line 43 "lib/tag_lookup.gperf"
      {"blockquote", GUMBO_TAG_BLOCKQUOTE},
#line 29 "lib/tag_lookup.gperf"
      {"aside", GUMBO_TAG_ASIDE},
      {""}, {""}, {""},
#line 101 "lib/tag_lookup.gperf"
      {"mn", GUMBO_TAG_MN},
#line 59 "lib/tag_lookup.gperf"
      {"cite", GUMBO_TAG_CITE},
      {""},
#line 131 "lib/tag_lookup.gperf"
      {"keygen", GUMBO_TAG_KEYGEN},
#line 112 "lib/tag_lookup.gperf"
      {"colgroup", GUMBO_TAG_COLGROUP},
#line 94 "lib/tag_lookup.gperf"
      {"track", GUMBO_TAG_TRACK},
      {""}, {""},
#line 91 "lib/tag_lookup.gperf"
      {"video", GUMBO_TAG_VIDEO},
#line 155 "lib/tag_lookup.gperf"
      {"big", GUMBO_TAG_BIG},
#line 132 "lib/tag_lookup.gperf"
      {"output", GUMBO_TAG_OUTPUT},
#line 106 "lib/tag_lookup.gperf"
      {"annotation-xml", GUMBO_TAG_ANNOTATION_XML},
#line 83 "lib/tag_lookup.gperf"
      {"ins", GUMBO_TAG_INS},
#line 69 "lib/tag_lookup.gperf"
      {"sub", GUMBO_TAG_SUB},
#line 86 "lib/tag_lookup.gperf"
      {"img", GUMBO_TAG_IMG},
#line 25 "lib/tag_lookup.gperf"
      {"body", GUMBO_TAG_BODY},
      {""}, {""}, {""},
#line 124 "lib/tag_lookup.gperf"
      {"input", GUMBO_TAG_INPUT},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
#line 107 "lib/tag_lookup.gperf"
      {"svg", GUMBO_TAG_SVG},
#line 111 "lib/tag_lookup.gperf"
      {"caption", GUMBO_TAG_CAPTION},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
#line 56 "lib/tag_lookup.gperf"
      {"strong", GUMBO_TAG_STRONG},
      {""}, {""},
#line 75 "lib/tag_lookup.gperf"
      {"ruby", GUMBO_TAG_RUBY},
      {""}, {""}, {""},
#line 136 "lib/tag_lookup.gperf"
      {"summary", GUMBO_TAG_SUMMARY},
#line 60 "lib/tag_lookup.gperf"
      {"q", GUMBO_TAG_Q},
      {""}, {""}, {""}, {""}, {""}, {""},
#line 92 "lib/tag_lookup.gperf"
      {"audio", GUMBO_TAG_AUDIO},
      {""}, {""}, {""}, {""}, {""},
#line 125 "lib/tag_lookup.gperf"
      {"button", GUMBO_TAG_BUTTON},
      {""}, {""}, {""}, {""}, {""}, {""},
#line 79 "lib/tag_lookup.gperf"
      {"bdo", GUMBO_TAG_BDO},
      {""}, {""}, {""},
#line 78 "lib/tag_lookup.gperf"
      {"bdi", GUMBO_TAG_BDI},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
#line 164 "lib/tag_lookup.gperf"
      {"rtc", GUMBO_TAG_RTC},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
#line 156 "lib/tag_lookup.gperf"
      {"blink", GUMBO_TAG_BLINK},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
#line 146 "lib/tag_lookup.gperf"
      {"isindex", GUMBO_TAG_ISINDEX}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register unsigned int key = hash (str, len);

      if (key <= MAX_HASH_VALUE)
        if (len == lengthtable[key])
          {
            register const char *s = wordlist[key].key;

            if (*str == *s && !memcmp (str + 1, s + 1, len - 1))
              return &wordlist[key];
          }
    }
  return 0;
}
