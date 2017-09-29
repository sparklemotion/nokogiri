// Copyright 2011 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Author: jdtang@google.com (Jonathan Tang)

#include "gumbo.h"

#include <assert.h>
#include <ctype.h>
#include <string.h>

const char* kGumboTagNames[] = {
#include "tag_strings.h"
    "",  // TAG_UNKNOWN
    "",  // TAG_LAST
};

static const struct {
    const char str[14];
    size_t len;
    GumboTag tag;
} tagmap[] = {
    {"a", 1, GUMBO_TAG_A},
    {"abbr", 4, GUMBO_TAG_ABBR},
    {"acronym", 7, GUMBO_TAG_ACRONYM},
    {"address", 7, GUMBO_TAG_ADDRESS},
    {"annotation-xml", 14, GUMBO_TAG_ANNOTATION_XML},
    {"applet", 6, GUMBO_TAG_APPLET},
    {"area", 4, GUMBO_TAG_AREA},
    {"article", 7, GUMBO_TAG_ARTICLE},
    {"aside", 5, GUMBO_TAG_ASIDE},
    {"audio", 5, GUMBO_TAG_AUDIO},
    {"b", 1, GUMBO_TAG_B},
    {"base", 4, GUMBO_TAG_BASE},
    {"basefont", 8, GUMBO_TAG_BASEFONT},
    {"bdi", 3, GUMBO_TAG_BDI},
    {"bdo", 3, GUMBO_TAG_BDO},
    {"bgsound", 7, GUMBO_TAG_BGSOUND},
    {"big", 3, GUMBO_TAG_BIG},
    {"blink", 5, GUMBO_TAG_BLINK},
    {"blockquote", 10, GUMBO_TAG_BLOCKQUOTE},
    {"body", 4, GUMBO_TAG_BODY},
    {"br", 2, GUMBO_TAG_BR},
    {"button", 6, GUMBO_TAG_BUTTON},
    {"canvas", 6, GUMBO_TAG_CANVAS},
    {"caption", 7, GUMBO_TAG_CAPTION},
    {"center", 6, GUMBO_TAG_CENTER},
    {"cite", 4, GUMBO_TAG_CITE},
    {"code", 4, GUMBO_TAG_CODE},
    {"col", 3, GUMBO_TAG_COL},
    {"colgroup", 8, GUMBO_TAG_COLGROUP},
    {"data", 4, GUMBO_TAG_DATA},
    {"datalist", 8, GUMBO_TAG_DATALIST},
    {"dd", 2, GUMBO_TAG_DD},
    {"del", 3, GUMBO_TAG_DEL},
    {"desc", 4, GUMBO_TAG_DESC},
    {"details", 7, GUMBO_TAG_DETAILS},
    {"dfn", 3, GUMBO_TAG_DFN},
    {"dir", 3, GUMBO_TAG_DIR},
    {"div", 3, GUMBO_TAG_DIV},
    {"dl", 2, GUMBO_TAG_DL},
    {"dt", 2, GUMBO_TAG_DT},
    {"em", 2, GUMBO_TAG_EM},
    {"embed", 5, GUMBO_TAG_EMBED},
    {"fieldset", 8, GUMBO_TAG_FIELDSET},
    {"figcaption", 10, GUMBO_TAG_FIGCAPTION},
    {"figure", 6, GUMBO_TAG_FIGURE},
    {"font", 4, GUMBO_TAG_FONT},
    {"footer", 6, GUMBO_TAG_FOOTER},
    {"foreignobject", 13, GUMBO_TAG_FOREIGNOBJECT},
    {"form", 4, GUMBO_TAG_FORM},
    {"frame", 5, GUMBO_TAG_FRAME},
    {"frameset", 8, GUMBO_TAG_FRAMESET},
    {"h1", 2, GUMBO_TAG_H1},
    {"h2", 2, GUMBO_TAG_H2},
    {"h3", 2, GUMBO_TAG_H3},
    {"h4", 2, GUMBO_TAG_H4},
    {"h5", 2, GUMBO_TAG_H5},
    {"h6", 2, GUMBO_TAG_H6},
    {"head", 4, GUMBO_TAG_HEAD},
    {"header", 6, GUMBO_TAG_HEADER},
    {"hgroup", 6, GUMBO_TAG_HGROUP},
    {"hr", 2, GUMBO_TAG_HR},
    {"html", 4, GUMBO_TAG_HTML},
    {"i", 1, GUMBO_TAG_I},
    {"iframe", 6, GUMBO_TAG_IFRAME},
    {"image", 5, GUMBO_TAG_IMAGE},
    {"img", 3, GUMBO_TAG_IMG},
    {"input", 5, GUMBO_TAG_INPUT},
    {"ins", 3, GUMBO_TAG_INS},
    {"isindex", 7, GUMBO_TAG_ISINDEX},
    {"kbd", 3, GUMBO_TAG_KBD},
    {"keygen", 6, GUMBO_TAG_KEYGEN},
    {"label", 5, GUMBO_TAG_LABEL},
    {"legend", 6, GUMBO_TAG_LEGEND},
    {"li", 2, GUMBO_TAG_LI},
    {"link", 4, GUMBO_TAG_LINK},
    {"listing", 7, GUMBO_TAG_LISTING},
    {"main", 4, GUMBO_TAG_MAIN},
    {"malignmark", 10, GUMBO_TAG_MALIGNMARK},
    {"map", 3, GUMBO_TAG_MAP},
    {"mark", 4, GUMBO_TAG_MARK},
    {"marquee", 7, GUMBO_TAG_MARQUEE},
    {"math", 4, GUMBO_TAG_MATH},
    {"menu", 4, GUMBO_TAG_MENU},
    {"menuitem", 8, GUMBO_TAG_MENUITEM},
    {"meta", 4, GUMBO_TAG_META},
    {"meter", 5, GUMBO_TAG_METER},
    {"mglyph", 6, GUMBO_TAG_MGLYPH},
    {"mi", 2, GUMBO_TAG_MI},
    {"mn", 2, GUMBO_TAG_MN},
    {"mo", 2, GUMBO_TAG_MO},
    {"ms", 2, GUMBO_TAG_MS},
    {"mtext", 5, GUMBO_TAG_MTEXT},
    {"multicol", 8, GUMBO_TAG_MULTICOL},
    {"nav", 3, GUMBO_TAG_NAV},
    {"nextid", 6, GUMBO_TAG_NEXTID},
    {"nobr", 4, GUMBO_TAG_NOBR},
    {"noembed", 7, GUMBO_TAG_NOEMBED},
    {"noframes", 8, GUMBO_TAG_NOFRAMES},
    {"noscript", 8, GUMBO_TAG_NOSCRIPT},
    {"object", 6, GUMBO_TAG_OBJECT},
    {"ol", 2, GUMBO_TAG_OL},
    {"optgroup", 8, GUMBO_TAG_OPTGROUP},
    {"option", 6, GUMBO_TAG_OPTION},
    {"output", 6, GUMBO_TAG_OUTPUT},
    {"p", 1, GUMBO_TAG_P},
    {"param", 5, GUMBO_TAG_PARAM},
    {"plaintext", 9, GUMBO_TAG_PLAINTEXT},
    {"pre", 3, GUMBO_TAG_PRE},
    {"progress", 8, GUMBO_TAG_PROGRESS},
    {"q", 1, GUMBO_TAG_Q},
    {"rb", 2, GUMBO_TAG_RB},
    {"rp", 2, GUMBO_TAG_RP},
    {"rt", 2, GUMBO_TAG_RT},
    {"rtc", 3, GUMBO_TAG_RTC},
    {"ruby", 4, GUMBO_TAG_RUBY},
    {"s", 1, GUMBO_TAG_S},
    {"samp", 4, GUMBO_TAG_SAMP},
    {"script", 6, GUMBO_TAG_SCRIPT},
    {"section", 7, GUMBO_TAG_SECTION},
    {"select", 6, GUMBO_TAG_SELECT},
    {"small", 5, GUMBO_TAG_SMALL},
    {"source", 6, GUMBO_TAG_SOURCE},
    {"spacer", 6, GUMBO_TAG_SPACER},
    {"span", 4, GUMBO_TAG_SPAN},
    {"strike", 6, GUMBO_TAG_STRIKE},
    {"strong", 6, GUMBO_TAG_STRONG},
    {"style", 5, GUMBO_TAG_STYLE},
    {"sub", 3, GUMBO_TAG_SUB},
    {"summary", 7, GUMBO_TAG_SUMMARY},
    {"sup", 3, GUMBO_TAG_SUP},
    {"svg", 3, GUMBO_TAG_SVG},
    {"table", 5, GUMBO_TAG_TABLE},
    {"tbody", 5, GUMBO_TAG_TBODY},
    {"td", 2, GUMBO_TAG_TD},
    {"template", 8, GUMBO_TAG_TEMPLATE},
    {"textarea", 8, GUMBO_TAG_TEXTAREA},
    {"tfoot", 5, GUMBO_TAG_TFOOT},
    {"th", 2, GUMBO_TAG_TH},
    {"thead", 5, GUMBO_TAG_THEAD},
    {"time", 4, GUMBO_TAG_TIME},
    {"title", 5, GUMBO_TAG_TITLE},
    {"tr", 2, GUMBO_TAG_TR},
    {"track", 5, GUMBO_TAG_TRACK},
    {"tt", 2, GUMBO_TAG_TT},
    {"u", 1, GUMBO_TAG_U},
    {"ul", 2, GUMBO_TAG_UL},
    {"var", 3, GUMBO_TAG_VAR},
    {"video", 5, GUMBO_TAG_VIDEO},
    {"wbr", 3, GUMBO_TAG_WBR},
    {"xmp", 3, GUMBO_TAG_XMP},
};

const char* gumbo_normalized_tagname(GumboTag tag) {
  assert(tag <= GUMBO_TAG_LAST);
  return kGumboTagNames[tag];
}

void gumbo_tag_from_original_text(GumboStringPiece* text) {
  if (text->data == NULL) {
    return;
  }

  assert(text->length >= 2);
  assert(text->data[0] == '<');
  assert(text->data[text->length - 1] == '>');
  if (text->data[1] == '/') {
    // End tag.
    assert(text->length >= 3);
    text->data += 2;  // Move past </
    text->length -= 3;
  } else {
    // Start tag.
    text->data += 1;  // Move past <
    text->length -= 2;
    // strnchr is apparently not a standard C library function, so I loop
    // explicitly looking for whitespace or other illegal tag characters.
    for (const char* c = text->data; c != text->data + text->length; ++c) {
      if (isspace(*c) || *c == '/') {
        text->length = c - text->data;
        break;
      }
    }
  }
}

GumboTag gumbo_tagn_enum(const char *tagname, size_t tagname_length) {
    // Longest known tag length is 14 bytes ("annotation-xml")
    if (tagname_length > 14 || tagname_length == 0) {
        return GUMBO_TAG_UNKNOWN;
    }

    // Convert tagname to lowercase
    char tagname_lower[15] = {'\0'};
    for (size_t i = 0; i < tagname_length; i++) {
        tagname_lower[i] = tolower(tagname[i]);
    }

    // TODO: Use binary search instead of linear search
    static const size_t nmemb = sizeof(tagmap) / sizeof(tagmap[0]);
    for (size_t i = 0; i < nmemb; i++) {
        if (tagname_length == tagmap[i].len) {
            if (strncmp(tagmap[i].str, tagname_lower, tagname_length) == 0) {
                return tagmap[i].tag;
            }
        }
    }

    return GUMBO_TAG_UNKNOWN;
}
