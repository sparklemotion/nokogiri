// Copyright 2018 Stephen Checkoway
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <string.h>

#include "token_buffer.h"
#include "tokenizer.h"

#include "gtest/gtest.h"
#include "test_utils.h"
#include "util.h"

namespace {

class GumboCharacterTokenBufferTest : public GumboTest {
 protected:
  GumboCharacterTokenBufferTest() {
    gumbo_character_token_buffer_init(&buffer_);
  }
  virtual ~GumboCharacterTokenBufferTest() {
    gumbo_character_token_buffer_destroy(&buffer_);
  }

  void Fill(const char* input, size_t size = -1) {
    gumbo_character_token_buffer_clear(&buffer_);
    if (size == static_cast<size_t>(-1))
      size = strlen(input);
    text_ = input;
    gumbo_tokenizer_state_init(&parser_, input, size);

    while (true) {
      GumboToken token;
      gumbo_lex(&parser_, &token);
      if (token.type == GUMBO_TOKEN_EOF) {
        gumbo_token_destroy(&token);
        break;
      }
      ASSERT_TRUE(token.type == GUMBO_TOKEN_CHARACTER
                  || token.type == GUMBO_TOKEN_WHITESPACE);
      gumbo_character_token_buffer_append(&token, &buffer_);
      gumbo_token_destroy(&token);
    }
  }

  GumboToken Get(size_t index) {
    GumboToken ret;
    gumbo_character_token_buffer_get(&buffer_, index, &ret);
    return ret;
  }

  GumboCharacterTokenBuffer buffer_;
};

TEST_F(GumboCharacterTokenBufferTest, AsciiCharacters) {
  Fill("abcXYZ!@#$%^&*()-=_+[]{}()");
  for (size_t i = 0; text_[i] != 0; ++i) {
    GumboToken t = Get(i);
    EXPECT_EQ(GUMBO_TOKEN_CHARACTER, t.type);
    EXPECT_EQ(text_[i], t.v.character);
    EXPECT_EQ(1, t.position.line);
    EXPECT_EQ(i+1, t.position.column);
    EXPECT_EQ(i, t.position.offset);
    EXPECT_EQ(&text_[i], t.original_text.data);
    EXPECT_EQ(1, t.original_text.length);
  }
}

TEST_F(GumboCharacterTokenBufferTest, Whitespace) {
  Fill("\n\f\t \r\r\n");
  GumboToken t = Get(0);
  EXPECT_EQ(GUMBO_TOKEN_WHITESPACE, t.type);
  EXPECT_EQ('\n', t.v.character);
  EXPECT_EQ(1, t.position.line);
  EXPECT_EQ(1, t.position.column);
  EXPECT_EQ(0, t.position.offset);
  EXPECT_EQ(&text_[0], t.original_text.data);
  EXPECT_EQ(1, t.original_text.length);

  t = Get(1);
  EXPECT_EQ(GUMBO_TOKEN_WHITESPACE, t.type);
  EXPECT_EQ('\f', t.v.character);
  EXPECT_EQ(2, t.position.line);
  EXPECT_EQ(1, t.position.column);
  EXPECT_EQ(1, t.position.offset);
  EXPECT_EQ(&text_[1], t.original_text.data);
  EXPECT_EQ(1, t.original_text.length);

  t = Get(2);
  EXPECT_EQ(GUMBO_TOKEN_WHITESPACE, t.type);
  EXPECT_EQ('\t', t.v.character);
  EXPECT_EQ(2, t.position.line);
  EXPECT_EQ(2, t.position.column);
  EXPECT_EQ(2, t.position.offset);
  EXPECT_EQ(&text_[2], t.original_text.data);
  EXPECT_EQ(1, t.original_text.length);

  t = Get(3);
  EXPECT_EQ(GUMBO_TOKEN_WHITESPACE, t.type);
  EXPECT_EQ(' ', t.v.character);
  EXPECT_EQ(2, t.position.line);
  EXPECT_EQ(8, t.position.column);
  EXPECT_EQ(3, t.position.offset);
  EXPECT_EQ(&text_[3], t.original_text.data);
  EXPECT_EQ(1, t.original_text.length);

  t = Get(4);
  EXPECT_EQ(GUMBO_TOKEN_WHITESPACE, t.type);
  EXPECT_EQ('\n', t.v.character);
  EXPECT_EQ(2, t.position.line);
  EXPECT_EQ(9, t.position.column);
  EXPECT_EQ(4, t.position.offset);
  EXPECT_EQ(&text_[4], t.original_text.data);
  EXPECT_EQ(1, t.original_text.length);

  t = Get(5);
  EXPECT_EQ(GUMBO_TOKEN_WHITESPACE, t.type);
  EXPECT_EQ('\n', t.v.character);
  EXPECT_EQ(3, t.position.line);
  EXPECT_EQ(1, t.position.column);
  EXPECT_EQ(6, t.position.offset);
  EXPECT_EQ(&text_[6], t.original_text.data);
  EXPECT_EQ(1, t.original_text.length);
}

TEST_F(GumboCharacterTokenBufferTest, Alternate) {
  Fill("a b c");
  for (size_t i = 0; text_[i] != 0; ++i) {
    GumboToken t = Get(i);
    if (i & 1)
      EXPECT_EQ(GUMBO_TOKEN_WHITESPACE, t.type);
    else
      EXPECT_EQ(GUMBO_TOKEN_CHARACTER, t.type);
    EXPECT_EQ(text_[i], t.v.character);
    EXPECT_EQ(1, t.position.line);
    EXPECT_EQ(i+1, t.position.column);
    EXPECT_EQ(i, t.position.offset);
    EXPECT_EQ(&text_[i], t.original_text.data);
    EXPECT_EQ(1, t.original_text.length);
  }
}

TEST_F(GumboCharacterTokenBufferTest, Entities) {
  Fill("&vnsub;&Uuml;");
  GumboToken t = Get(0);
  EXPECT_EQ(GUMBO_TOKEN_CHARACTER, t.type);
  EXPECT_EQ(0x2282, t.v.character);
  EXPECT_EQ(1, t.position.line);
  EXPECT_EQ(1, t.position.column);
  EXPECT_EQ(0, t.position.offset);
  EXPECT_EQ(&text_[0], t.original_text.data);
  EXPECT_EQ(7, t.original_text.length);

  t = Get(1);
  EXPECT_EQ(GUMBO_TOKEN_CHARACTER, t.type);
  EXPECT_EQ(0x20D2, t.v.character);
  // XXX: These should probably report the same location in the source as the
  // first token from the entity.
  // EXPECT_EQ(1, t.position.line);
  // EXPECT_EQ(1, t.position.column);
  // EXPECT_EQ(0, t.position.offset);
  // EXPECT_EQ(&text_[0], t.original_text.data);
  // EXPECT_EQ(7, t.original_text.length);

  t = Get(2);
  EXPECT_EQ(GUMBO_TOKEN_CHARACTER, t.type);
  EXPECT_EQ(0x00DC, t.v.character);
  EXPECT_EQ(1, t.position.line);
  EXPECT_EQ(8, t.position.column);
  EXPECT_EQ(7, t.position.offset);
  EXPECT_EQ(&text_[7], t.original_text.data);
  EXPECT_EQ(6, t.original_text.length);
}

TEST_F(GumboCharacterTokenBufferTest, CarriageReturn) {
  Fill("&#x0d;");
  GumboToken t = Get(0);
  EXPECT_EQ(GUMBO_TOKEN_WHITESPACE, t.type);
  EXPECT_EQ(0x000D, t.v.character);
  EXPECT_EQ(1, t.position.line);
  EXPECT_EQ(1, t.position.column);
  EXPECT_EQ(0, t.position.offset);
  EXPECT_EQ(&text_[0], t.original_text.data);
  EXPECT_EQ(6, t.original_text.length);
  errors_are_expected_ = true;
}

}  // namespace

// vim: set sw=2 sts=2 ts=8 et:
