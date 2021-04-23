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

#include <stddef.h>
#include "vector.h"
#include "gtest/gtest.h"
#include "test_utils.h"

namespace {

class GumboVectorTest : public GumboTest {
 protected:
  GumboVectorTest(): one_(1), two_(2), three_(3) {
    gumbo_vector_init(2, &vector_);
  }

  ~GumboVectorTest() { gumbo_vector_destroy(&vector_); }

  GumboVector vector_;

  // dummy ints that we can use to take addresses of.
  int one_;
  int two_;
  int three_;
};

TEST_F(GumboVectorTest, Init) {
  EXPECT_EQ(0, vector_.length);
  EXPECT_EQ(2, vector_.capacity);
}

TEST_F(GumboVectorTest, InitZeroCapacity) {
  gumbo_vector_destroy(&vector_);
  gumbo_vector_init(0, &vector_);

  gumbo_vector_add(&one_, &vector_);
  EXPECT_EQ(1, vector_.length);
  EXPECT_EQ(1, *(static_cast<int*>(vector_.data[0])));
}

TEST_F(GumboVectorTest, Add) {
  gumbo_vector_add(&one_, &vector_);
  EXPECT_EQ(1, vector_.length);
  EXPECT_EQ(1, *(static_cast<int*>(vector_.data[0])));
  EXPECT_EQ(0, gumbo_vector_index_of(&vector_, &one_));
  EXPECT_EQ(-1, gumbo_vector_index_of(&vector_, &two_));
}

TEST_F(GumboVectorTest, AddMultiple) {
  gumbo_vector_add(&one_, &vector_);
  gumbo_vector_add(&two_, &vector_);
  EXPECT_EQ(2, vector_.length);
  EXPECT_EQ(2, *(static_cast<int*>(vector_.data[1])));
  EXPECT_EQ(1, gumbo_vector_index_of(&vector_, &two_));
}

TEST_F(GumboVectorTest, Realloc) {
  gumbo_vector_add(&one_, &vector_);
  gumbo_vector_add(&two_, &vector_);
  gumbo_vector_add(&three_, &vector_);
  EXPECT_EQ(3, vector_.length);
  EXPECT_EQ(4, vector_.capacity);
  EXPECT_EQ(3, *(static_cast<int*>(vector_.data[2])));
}

TEST_F(GumboVectorTest, Pop) {
  gumbo_vector_add(&one_, &vector_);
  int result = *static_cast<int*>(gumbo_vector_pop(&vector_));
  EXPECT_EQ(1, result);
  EXPECT_EQ(0, vector_.length);
}

TEST_F(GumboVectorTest, PopEmpty) {
  EXPECT_EQ(NULL, gumbo_vector_pop(&vector_));
}

TEST_F(GumboVectorTest, InsertAtFirst) {
  gumbo_vector_add(&one_, &vector_);
  gumbo_vector_add(&two_, &vector_);
  gumbo_vector_insert_at(&three_, 0, &vector_);
  EXPECT_EQ(3, vector_.length);
  int result = *static_cast<int*>(vector_.data[0]);
  EXPECT_EQ(3, result);
}

TEST_F(GumboVectorTest, InsertAtLast) {
  gumbo_vector_add(&one_, &vector_);
  gumbo_vector_add(&two_, &vector_);
  gumbo_vector_insert_at(&three_, 2, &vector_);
  EXPECT_EQ(3, vector_.length);
  int result = *static_cast<int*>(vector_.data[2]);
  EXPECT_EQ(3, result);
}

TEST_F(GumboVectorTest, Remove) {
  gumbo_vector_add(&one_, &vector_);
  gumbo_vector_add(&two_, &vector_);
  gumbo_vector_add(&three_, &vector_);
  gumbo_vector_remove(&two_, &vector_);
  EXPECT_EQ(2, vector_.length);
  int three = *static_cast<int*>(vector_.data[1]);
  EXPECT_EQ(3, three);
}

TEST_F(GumboVectorTest, RemoveAt) {
  gumbo_vector_add(&one_, &vector_);
  gumbo_vector_add(&two_, &vector_);
  gumbo_vector_add(&three_, &vector_);
  int result = *static_cast<int*>(gumbo_vector_remove_at(1, &vector_));
  EXPECT_EQ(2, result);
  EXPECT_EQ(2, vector_.length);
  int three = *static_cast<int*>(vector_.data[1]);
  EXPECT_EQ(3, three);
}

}  // namespace
