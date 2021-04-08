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

#include "attribute.h"

#include <stdlib.h>
#include <string.h>

#include "gtest/gtest.h"
#include "test_utils.h"
#include "vector.h"

namespace {

class GumboAttributeTest : public GumboTest {
 protected:
  GumboAttributeTest() { gumbo_vector_init(2, &vector_); }

  ~GumboAttributeTest() { gumbo_vector_destroy(&vector_); }

  GumboVector vector_;
};

TEST_F(GumboAttributeTest, GetAttribute) {
  GumboAttribute attr1;
  GumboAttribute attr2;
  attr1.name = "";
  attr2.name = "foo";

  gumbo_vector_add(&attr1, &vector_);
  gumbo_vector_add(&attr2, &vector_);
  EXPECT_EQ(&attr2, gumbo_get_attribute(&vector_, "foo"));
  EXPECT_EQ(NULL, gumbo_get_attribute(&vector_, "bar"));
}

}  // namespace
