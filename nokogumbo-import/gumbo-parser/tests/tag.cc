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

#include <string.h>

#include "gtest/gtest.h"
#include "error.h"
#include "test_utils.h"

namespace {

// Tests for tag.c
class TagTest : public GumboTest {
};

TEST_F(TagTest, AllowedWhitespacesInTagName) {
  GumboStringPiece sp;
  sp.data = "<script\v\r>";
  const size_t len = strlen(sp.data);
  sp.length = len;

  gumbo_tag_from_original_text(&sp);
  EXPECT_EQ(len - 2, sp.length);
  EXPECT_EQ(memcmp(sp.data, "script\v\r", len - 2), 0);
}

TEST_F(TagTest, IllegalCharsInTagName) {
  const char illegal_chars[] = { '\t', '\n', '\f', ' ', '/' };
  char pattern[] = "<scr?ipt>"; // ? as a placeholder

  for (size_t i = 0; i < sizeof(illegal_chars) / sizeof(char); ++i) {
    GumboStringPiece sp;
    sp.data = pattern;
    const size_t len = strlen(sp.data);
    sp.length = len;

    pattern[4] = illegal_chars[i];

    gumbo_tag_from_original_text(&sp);
    EXPECT_EQ(3, sp.length);
    EXPECT_EQ(memcmp(sp.data, "scr", 3), 0);
  }
}

}  // namespace
