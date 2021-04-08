// Copyright 2011 Google Inc. All Rights Reserved.
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
//
// Author: jdtang@google.com (Jonathan Tang)

#include "test_utils.h"

namespace {

typedef GumboTest GumboStringPieceTest;

#define STRING(s) {"" s, sizeof(s) - 1}

TEST_F(GumboStringPieceTest, Equal) {
  const GumboStringPiece str1 = STRING("foo");
  const GumboStringPiece str2 = STRING("foo");
  EXPECT_TRUE(gumbo_string_equals(&str1, &str2));
}

TEST_F(GumboStringPieceTest, NotEqual_DifferingCase) {
  const GumboStringPiece str1 = STRING("foo");
  const GumboStringPiece str2 = STRING("Foo");
  EXPECT_FALSE(gumbo_string_equals(&str1, &str2));
}

TEST_F(GumboStringPieceTest, NotEqual_Str1Shorter) {
  const GumboStringPiece str1 = STRING("foo");
  const GumboStringPiece str2 = STRING("foobar");
  EXPECT_FALSE(gumbo_string_equals(&str1, &str2));
}

TEST_F(GumboStringPieceTest, NotEqual_Str2Shorter) {
  const GumboStringPiece str1 = STRING("foobar");
  const GumboStringPiece str2 = STRING("foo");
  EXPECT_FALSE(gumbo_string_equals(&str1, &str2));
}

TEST_F(GumboStringPieceTest, NotEqual_DifferentText) {
  const GumboStringPiece str1 = STRING("bar");
  const GumboStringPiece str2 = STRING("foo");
  EXPECT_FALSE(gumbo_string_equals(&str1, &str2));
}

TEST_F(GumboStringPieceTest, CaseEqual) {
  const GumboStringPiece str1 = STRING("foo");
  const GumboStringPiece str2 = STRING("fOO");
  EXPECT_TRUE(gumbo_string_equals_ignore_case(&str1, &str2));
}

TEST_F(GumboStringPieceTest, CaseNotEqual_Str2Shorter) {
  const GumboStringPiece str1 = STRING("foobar");
  const GumboStringPiece str2 = STRING("foo");
  EXPECT_FALSE(gumbo_string_equals_ignore_case(&str1, &str2));
}

}  // namespace
