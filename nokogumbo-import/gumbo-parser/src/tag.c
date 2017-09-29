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
#include "tag_lookup.h"

#include <assert.h>
#include <ctype.h>
#include <string.h>

const char* kGumboTagNames[] = {
#include "tag_strings.h"
    "",  // TAG_UNKNOWN
    "",  // TAG_LAST
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

    const TagHashSlot *slot = gumbo_tag_lookup(tagname_lower, tagname_length);
    return slot ? slot->tag : GUMBO_TAG_UNKNOWN;
}
