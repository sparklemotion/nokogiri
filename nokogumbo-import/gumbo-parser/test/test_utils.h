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

#ifndef GUMBO_TEST_UTILS_H_
#define GUMBO_TEST_UTILS_H_

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <string>

#include "gtest/gtest.h"
#include "gumbo.h"
#include "parser.h"

inline std::string ToString(const GumboStringPiece& str) {
  return std::string(str.data, str.length);
}

int GetChildCount(GumboNode* node);
GumboTag GetTag(GumboNode* node);
GumboNode* GetChild(GumboNode* parent, int index);
int GetAttributeCount(GumboNode* node);
GumboAttribute* GetAttribute(GumboNode* node, int index);

// Convenience function to do some basic assertions on the structure of the
// document (nodes are elements, nodes have the right tags) and then return
// the body node.
void GetAndAssertBody(GumboNode* root, GumboNode** body);

void SanityCheckPointers (
  const char* input,
  size_t input_length,
  const GumboNode* node,
  int depth
);

// Base class for Gumbo tests. This provides an GumboParser object that's
// been initialized to sane values, as normally happens in the beginning of
// gumbo_parse, and then a destructor that cleans up after it.
class GumboTest : public ::testing::Test {
 protected:
  GumboTest();
  virtual ~GumboTest();

  GumboOptions options_;
  GumboParser parser_;
  bool errors_are_expected_;
  const char* text_;
};

#endif  // GUMBO_TEST_UTILS_H_
