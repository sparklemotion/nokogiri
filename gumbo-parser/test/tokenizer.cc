// Copyright 2011 Google Inc.
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
//
// Author: jdtang@google.com (Jonathan Tang)

#include <stdio.h>

#include "gtest/gtest.h"
#include "test_utils.h"

#include "tokenizer.h"
#include "error.h"

extern const char* kGumboTagNames[];

namespace {

// Tests for tokenizer.c
class GumboTokenizerTest : public GumboTest {
 protected:
  GumboTokenizerTest() : at_start_(true), error_index_(0) {
    gumbo_tokenizer_state_init(&parser_, "", 0);
  }

  virtual ~GumboTokenizerTest() {
    EXPECT_EQ(error_index_, parser_._output->errors.length);
    gumbo_tokenizer_state_destroy(&parser_);
    gumbo_token_destroy(&token_);
  }

  void SetInput(const char* input, size_t size = -1) {
    if (!at_start_)
      gumbo_token_destroy(&token_);
    text_ = input;
    gumbo_tokenizer_state_destroy(&parser_);
    if (size == static_cast<size_t>(-1))
      size = strlen(input);
    gumbo_tokenizer_state_init(&parser_, input, size);
    at_start_ = true;
    error_index_ = 0;
  }

  void SetState(GumboTokenizerEnum state) {
    gumbo_tokenizer_set_state(&parser_, state);
  }

  void Foreign() {
    gumbo_tokenizer_set_is_adjusted_current_node_foreign(&parser_, true);
  }

  void Advance(int num_tokens) {
    for (int i = 0; i < num_tokens; ++i) {
      Next();
      ASSERT_NE(GUMBO_TOKEN_EOF, token_.type);
    }
  }

  void Next(bool errors_are_expected = false) {
    if (!at_start_)
      gumbo_token_destroy(&token_);
    at_start_ = false;
    // Reset the document errors.
    parser_._output->document_error = false;
    gumbo_lex(&parser_, &token_);
    EXPECT_EQ(errors_are_expected, parser_._output->document_error);
    errors_are_expected_ = errors_are_expected;
  }

  void NextChar(int c, bool errors_are_expected = false) {
    Next(errors_are_expected);
    ASSERT_EQ(GUMBO_TOKEN_CHARACTER, token_.type);
    EXPECT_EQ(c, token_.v.character);
  }

  void NextCdata(int c, bool errors_are_expected = false) {
    Next(errors_are_expected);
    ASSERT_EQ(GUMBO_TOKEN_CDATA, token_.type);
    EXPECT_EQ(c, token_.v.character);
  }

  void NextSpace(int c, bool errors_are_expected = false) {
    Next(errors_are_expected);
    ASSERT_EQ(GUMBO_TOKEN_WHITESPACE, token_.type);
    EXPECT_EQ(c, token_.v.character);
  }

  void NextStartTag(GumboTag tag, bool errors_are_expected = false) {
    Next(errors_are_expected);
    ASSERT_EQ(GUMBO_TOKEN_START_TAG, token_.type);
    EXPECT_EQ(tag, token_.v.start_tag.tag);
  }

  void NextEndTag(GumboTag tag, bool errors_are_expected = false) {
    Next(errors_are_expected);
    ASSERT_EQ(GUMBO_TOKEN_END_TAG, token_.type);
    EXPECT_EQ(tag, token_.v.end_tag.tag);
  }

  void NextComment(const char *text, bool errors_are_expected = false) {
    Next(errors_are_expected);
    ASSERT_EQ(GUMBO_TOKEN_COMMENT, token_.type);
    EXPECT_STREQ(text, token_.v.text);
  }

  void NextDoctype(const char *name, const char *pub, const char *sys, bool errors_are_expected = false) {
    Next(errors_are_expected);
    ASSERT_EQ(GUMBO_TOKEN_DOCTYPE, token_.type);
    // XXX: There's a difference between missing and empty.
    if (!name)
      name = "";
    EXPECT_STREQ(name, token_.v.doc_type.name);
    if (!pub) {
      EXPECT_FALSE(token_.v.doc_type.has_public_identifier);
    } else {
      EXPECT_TRUE(token_.v.doc_type.has_public_identifier);
      EXPECT_STREQ(pub, token_.v.doc_type.public_identifier);
    }
    if (!sys) {
      EXPECT_FALSE(token_.v.doc_type.has_system_identifier);
    } else {
      EXPECT_TRUE(token_.v.doc_type.has_system_identifier);
      EXPECT_STREQ(sys, token_.v.doc_type.system_identifier);
    }
  }

  void AtEnd(bool errors_are_expected = false) {
    Next(errors_are_expected);
    ASSERT_EQ(GUMBO_TOKEN_EOF, token_.type);
    EXPECT_EQ(-1, token_.v.character);
  }

  void Error(GumboErrorType err) {
    ASSERT_LT(error_index_, parser_._output->errors.length);
    GumboError* error =
      static_cast<GumboError*>(parser_._output->errors.data[error_index_++]);
    EXPECT_EQ(err, error->type);
  }

  bool at_start_;
  size_t error_index_;
  GumboToken token_;
};

TEST(GumboTagEnumTest, TagEnumIncludesAllTags) {
  EXPECT_EQ(0, GUMBO_TAG_HTML);
  for (unsigned int i = 0; i < (unsigned int) GUMBO_TAG_UNKNOWN; i++) {
    const char* tagname = gumbo_normalized_tagname((GumboTag)i);
    EXPECT_FALSE(tagname == NULL);
    EXPECT_FALSE(tagname[0] == '\0');
    EXPECT_TRUE(strlen(tagname) < 15);
  }
  EXPECT_STREQ("", gumbo_normalized_tagname(GUMBO_TAG_UNKNOWN));
  EXPECT_STREQ("html", gumbo_normalized_tagname(GUMBO_TAG_HTML));
  EXPECT_STREQ("a", gumbo_normalized_tagname(GUMBO_TAG_A));
  EXPECT_STREQ("dialog", gumbo_normalized_tagname(GUMBO_TAG_DIALOG));
  EXPECT_STREQ("template", gumbo_normalized_tagname(GUMBO_TAG_TEMPLATE));
}

TEST(GumboTagEnumTest, TagLookupCaseSensitivity) {
  EXPECT_EQ(GUMBO_TAG_HTML, gumbo_tagn_enum("HTML", 4));
  EXPECT_EQ(GUMBO_TAG_BODY, gumbo_tagn_enum("boDy", 4));
  EXPECT_EQ(GUMBO_TAG_A, gumbo_tagn_enum("A", 1));
  EXPECT_EQ(GUMBO_TAG_A, gumbo_tagn_enum("a", 1));
  EXPECT_EQ(GUMBO_TAG_TEMPLATE, gumbo_tagn_enum("Template", 8));
  EXPECT_EQ(GUMBO_TAG_DIALOG, gumbo_tagn_enum("diAloG", 6));
  EXPECT_EQ(GUMBO_TAG_ANNOTATION_XML, gumbo_tagn_enum("annotation-xml", 14));
  EXPECT_EQ(GUMBO_TAG_ANNOTATION_XML, gumbo_tagn_enum("ANNOTATION-XML", 14));
  EXPECT_EQ(GUMBO_TAG_UNKNOWN, gumbo_tagn_enum("ANNOTATION-XML-", 15));
  EXPECT_EQ(GUMBO_TAG_UNKNOWN, gumbo_tagn_enum("ANNOTATION-XM", 13));
  EXPECT_EQ(GUMBO_TAG_UNKNOWN, gumbo_tagn_enum("", 0));
  EXPECT_EQ(GUMBO_TAG_B, gumbo_tagn_enum("b", 1));
  EXPECT_EQ(GUMBO_TAG_I, gumbo_tagn_enum("i", 1));
  EXPECT_EQ(GUMBO_TAG_U, gumbo_tagn_enum("u", 1));
  EXPECT_EQ(GUMBO_TAG_UNKNOWN, gumbo_tagn_enum("x", 1));
  EXPECT_EQ(GUMBO_TAG_UNKNOWN, gumbo_tagn_enum("c", 1));
}

TEST_F(GumboTokenizerTest, LexCharToken) {
  SetInput("a");
  NextChar('a');
  EXPECT_EQ(1, token_.position.column);
  EXPECT_EQ(1, token_.position.line);
  EXPECT_EQ(0, token_.position.offset);
  EXPECT_EQ('a', *token_.original_text.data);
  EXPECT_EQ(1, token_.original_text.length);
  EXPECT_EQ('a', token_.v.character);

  AtEnd();
  EXPECT_EQ(1, token_.position.offset);
}

TEST_F(GumboTokenizerTest, AttrWithCRNL) {
  SetInput("<span FOO\r\n=''>");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_EQ(3, attr->original_name.length);
  EXPECT_EQ('O', attr->original_name.data[attr->original_name.length-1]);
  AtEnd();
}

TEST_F(GumboTokenizerTest, LexCharRef) {
  SetInput("&nbsp; Text");
  NextChar(0xa0);
  EXPECT_EQ(1, token_.position.column);
  EXPECT_EQ(1, token_.position.line);
  EXPECT_EQ(0, token_.position.offset);
  EXPECT_EQ('&', *token_.original_text.data);
  EXPECT_EQ(6, token_.original_text.length);

  NextSpace(' ');
  EXPECT_EQ(' ', *token_.original_text.data);

  NextChar('T');
  NextChar('e');
  NextChar('x');
  NextChar('t');
  AtEnd();
}

TEST_F(GumboTokenizerTest, LexCharRef_NotCharRef) {
  SetInput("&xyz");
  NextChar('&');
  EXPECT_EQ(0, token_.position.offset);

  NextChar('x');
  EXPECT_EQ(1, token_.position.offset);

  NextChar('y');
  EXPECT_EQ(2, token_.position.offset);

  NextChar('z');
  EXPECT_EQ(3, token_.position.offset);

  AtEnd();
}

TEST_F(GumboTokenizerTest, LeadingWhitespace) {
  SetInput(
      "<div>\n"
      "  <span class=foo>");
  Advance(4);

  NextStartTag(GUMBO_TAG_SPAN);
  EXPECT_EQ(2, token_.position.line);
  EXPECT_EQ(3, token_.position.column);
  GumboTokenStartTag* start_tag = &token_.v.start_tag;
  ASSERT_EQ(1, start_tag->attributes.length);

  GumboAttribute* clas =
      static_cast<GumboAttribute*>(start_tag->attributes.data[0]);
  EXPECT_STREQ("class", clas->name);
  EXPECT_EQ("class", ToString(clas->original_name));
  EXPECT_EQ(2, clas->name_start.line);
  EXPECT_EQ(9, clas->name_start.column);
  EXPECT_EQ(14, clas->name_end.column);
  EXPECT_STREQ("foo", clas->value);
  EXPECT_EQ("foo", ToString(clas->original_value));
  EXPECT_EQ(15, clas->value_start.column);
  EXPECT_EQ(18, clas->value_end.column);
}

TEST_F(GumboTokenizerTest, Doctype) {
  SetInput("<!doctype html>");
  Next();
  ASSERT_EQ(GUMBO_TOKEN_DOCTYPE, token_.type);
  EXPECT_EQ(0, token_.position.offset);

  GumboTokenDocType* doc_type = &token_.v.doc_type;
  EXPECT_FALSE(doc_type->force_quirks);
  EXPECT_FALSE(doc_type->has_public_identifier);
  EXPECT_FALSE(doc_type->has_system_identifier);
  EXPECT_STREQ("html", doc_type->name);
  EXPECT_STREQ("", doc_type->public_identifier);
  EXPECT_STREQ("", doc_type->system_identifier);
}

TEST_F(GumboTokenizerTest, DoctypePublic) {
  SetInput(
      "<!DOCTYPE html PUBLIC "
      "\"-//W3C//DTD XHTML 1.0 Transitional//EN\" "
      "'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>");
  Next();
  ASSERT_EQ(GUMBO_TOKEN_DOCTYPE, token_.type);
  EXPECT_EQ(0, token_.position.offset);

  GumboTokenDocType* doc_type = &token_.v.doc_type;
  EXPECT_FALSE(doc_type->force_quirks);
  EXPECT_TRUE(doc_type->has_public_identifier);
  EXPECT_TRUE(doc_type->has_system_identifier);
  EXPECT_STREQ("html", doc_type->name);
  EXPECT_STREQ(
      "-//W3C//DTD XHTML 1.0 Transitional//EN", doc_type->public_identifier);
  EXPECT_STREQ("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd",
      doc_type->system_identifier);
}

TEST_F(GumboTokenizerTest, DoctypeSystem) {
  SetInput("<!DOCtype root_element SYSTEM \"DTD_location\">");
  Next();
  ASSERT_EQ(GUMBO_TOKEN_DOCTYPE, token_.type);
  EXPECT_EQ(0, token_.position.offset);

  GumboTokenDocType* doc_type = &token_.v.doc_type;
  EXPECT_FALSE(doc_type->force_quirks);
  EXPECT_FALSE(doc_type->has_public_identifier);
  EXPECT_TRUE(doc_type->has_system_identifier);
  EXPECT_STREQ("root_element", doc_type->name);
  EXPECT_STREQ("DTD_location", doc_type->system_identifier);
}

TEST_F(GumboTokenizerTest, RawtextEnd) {
  SetInput("<title>x ignores <tag></title>");
  NextStartTag(GUMBO_TAG_TITLE);
  gumbo_tokenizer_set_state(&parser_, GUMBO_LEX_RAWTEXT);
  NextChar('x');
  Advance(9);
  NextChar('<');
  NextChar('t');
  Advance(3);
  NextEndTag(GUMBO_TAG_TITLE);
  AtEnd();
}

TEST_F(GumboTokenizerTest, RCDataEnd) {
  SetInput("<title>x</title>");
  NextStartTag(GUMBO_TAG_TITLE);
  gumbo_tokenizer_set_state(&parser_, GUMBO_LEX_RCDATA);
  NextChar('x');
  NextEndTag(GUMBO_TAG_TITLE);
}

TEST_F(GumboTokenizerTest, ScriptEnd) {
  SetInput("<script>x = '\"></';</script>");
  NextStartTag(GUMBO_TAG_SCRIPT);

  gumbo_tokenizer_set_state(&parser_, GUMBO_LEX_SCRIPT_DATA);
  NextChar('x');

  Advance(6);
  NextChar('<');
  NextChar('/');
  NextChar('\'');
  NextChar(';');
  NextEndTag(GUMBO_TAG_SCRIPT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, ScriptEscapedEnd) {
  SetInput("<title>x</title>");
  NextStartTag(GUMBO_TAG_TITLE);
  gumbo_tokenizer_set_state(&parser_, GUMBO_LEX_SCRIPT_DATA_ESCAPED);
  NextChar('x');
  NextEndTag(GUMBO_TAG_TITLE);
  AtEnd();
}

TEST_F(GumboTokenizerTest, ScriptCommentEscaped) {
  SetInput(
      "<script><!-- var foo = x < 7 + '</div>-- <A href=\"foo\"></a>';\n"
      "-->\n"
      "</script>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  gumbo_tokenizer_set_state(&parser_, GUMBO_LEX_SCRIPT_DATA);
  Advance(15);
  NextChar('x');
  NextSpace(' ');
  NextChar('<');
  NextSpace(' ');
  NextChar('7');
  Advance(4);
  NextChar('<');
  NextChar('/');
  NextChar('d');
  Advance(27);
  NextChar('-');
  NextChar('-');
  NextChar('>');
  NextSpace('\n');
  NextEndTag(GUMBO_TAG_SCRIPT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, ScriptEscapedEmbeddedLessThan) {
  SetInput("<script>/*<![CDATA[*/ x<7 /*]]>*/</script>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  gumbo_tokenizer_set_state(&parser_, GUMBO_LEX_SCRIPT_DATA);
  Advance(14);
  NextChar('x');
  NextChar('<');
  NextChar('7');
  Advance(8);
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptHasTagEmbedded) {
  SetInput("<script>var foo = '</div>';</script>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  gumbo_tokenizer_set_state(&parser_, GUMBO_LEX_SCRIPT_DATA);
  Advance(11);
  NextChar('<');
  NextChar('/');
  NextChar('d');
  NextChar('i');
  Advance(4);
  NextEndTag(GUMBO_TAG_SCRIPT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, ScriptDoubleEscaped) {
  SetInput(
      "<script><!--var foo = '<a href=\"foo\"></a>\n"
      "<sCrIpt>i--<f</script>'-->;</script>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  gumbo_tokenizer_set_state(&parser_, GUMBO_LEX_SCRIPT_DATA);
  Advance(34);

  NextChar('<');
  NextChar('s');
  NextChar('C');
  Advance(20);
  NextChar('-');
  NextChar('-');
  NextChar('>');
  NextChar(';');
  NextEndTag(GUMBO_TAG_SCRIPT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, CDataNulls) {
  SetInput("<![CDATA[\0filter\0text\0]]>", sizeof("<![CDATA[\0filter\0text\0]]>")-1);
  Foreign();

  Next();
  EXPECT_EQ(GUMBO_TOKEN_NULL, token_.type);
  EXPECT_EQ(0, token_.v.character);
  Next();
  EXPECT_EQ(GUMBO_TOKEN_CDATA, token_.type);
  EXPECT_EQ('f', token_.v.character);
}

TEST_F(GumboTokenizerTest, StyleHasTagEmbedded) {
  SetInput("<style>/* For <head> */</style>");
  NextStartTag(GUMBO_TAG_STYLE);
  gumbo_tokenizer_set_state(&parser_, GUMBO_LEX_RCDATA);
  Advance(7);
  NextChar('<');
  NextChar('h');
  NextChar('e');
}

TEST_F(GumboTokenizerTest, PreWithNewlines) {
  SetInput("<!DOCTYPE html><pre>\r\na</pre>");
  Next();
  ASSERT_EQ(GUMBO_TOKEN_DOCTYPE, token_.type);
  EXPECT_EQ(0, token_.position.offset);

  NextStartTag(GUMBO_TAG_PRE);
  EXPECT_EQ("<pre>", ToString(token_.original_text));
  EXPECT_EQ(15, token_.position.offset);
}

TEST_F(GumboTokenizerTest, SelfClosingStartTag) {
  SetInput("<br />");
  NextStartTag(GUMBO_TAG_BR);
  EXPECT_EQ(0, token_.position.offset);
  EXPECT_EQ("<br />", ToString(token_.original_text));

  GumboTokenStartTag* start_tag = &token_.v.start_tag;
  EXPECT_EQ(0, start_tag->attributes.length);
  EXPECT_TRUE(start_tag->is_self_closing);
}

TEST_F(GumboTokenizerTest, SelfClosingEndTag) {
  SetInput("</p />");
  NextEndTag(GUMBO_TAG_P, true);
  Error(GUMBO_ERR_END_TAG_WITH_TRAILING_SOLIDUS);
  EXPECT_EQ(0, token_.position.offset);
  EXPECT_EQ("</p />", ToString(token_.original_text));
  AtEnd();
}

TEST_F(GumboTokenizerTest, OpenTagWithAttributes) {
  SetInput("<a href ='/search?q=foo&amp;hl=en'  id=link>");
  NextStartTag(GUMBO_TAG_A);

  GumboTokenStartTag* start_tag = &token_.v.start_tag;
  EXPECT_FALSE(start_tag->is_self_closing);
  ASSERT_EQ(2, start_tag->attributes.length);

  GumboAttribute* href =
      static_cast<GumboAttribute*>(start_tag->attributes.data[0]);
  EXPECT_STREQ("href", href->name);
  EXPECT_EQ("href", ToString(href->original_name));
  EXPECT_STREQ("/search?q=foo&hl=en", href->value);
  EXPECT_EQ("'/search?q=foo&amp;hl=en'", ToString(href->original_value));

  GumboAttribute* id =
      static_cast<GumboAttribute*>(start_tag->attributes.data[1]);
  EXPECT_STREQ("id", id->name);
  EXPECT_EQ("id", ToString(id->original_name));
  EXPECT_STREQ("link", id->value);
  EXPECT_EQ("link", ToString(id->original_value));
  AtEnd();
}

TEST_F(GumboTokenizerTest, BogusComment1) {
  SetInput("<?xml is bogus-comment>Text");
  NextComment("?xml is bogus-comment", true);
  Error(GUMBO_ERR_UNEXPECTED_QUESTION_MARK_INSTEAD_OF_TAG_NAME);
  NextChar('T');
  NextChar('e');
  NextChar('x');
  NextChar('t');
  AtEnd();
}

TEST_F(GumboTokenizerTest, BogusComment2) {
  SetInput("</#bogus-comment");
  NextComment("#bogus-comment", true);
  Error(GUMBO_ERR_INVALID_FIRST_CHARACTER_OF_TAG_NAME);
  AtEnd();
}

TEST_F(GumboTokenizerTest, MultilineAttribute) {
  SetInput(
      "<foo long_attr=\"SomeCode;\n"
      "  calls_a_big_long_function();\n"
      "  return true;\" />");
  NextStartTag(GUMBO_TAG_UNKNOWN);

  GumboTokenStartTag* start_tag = &token_.v.start_tag;
  EXPECT_TRUE(start_tag->is_self_closing);
  ASSERT_EQ(1, start_tag->attributes.length);

  GumboAttribute* long_attr =
      static_cast<GumboAttribute*>(start_tag->attributes.data[0]);
  EXPECT_STREQ("long_attr", long_attr->name);
  EXPECT_EQ("long_attr", ToString(long_attr->original_name));
  EXPECT_STREQ(
      "SomeCode;\n"
      "  calls_a_big_long_function();\n"
      "  return true;",
      long_attr->value);
  AtEnd();
}

TEST_F(GumboTokenizerTest, DoubleAmpersand) {
  SetInput("<span jsif=\"foo && bar\">");
  NextStartTag(GUMBO_TAG_SPAN);
  GumboTokenStartTag* start_tag = &token_.v.start_tag;
  EXPECT_FALSE(start_tag->is_self_closing);
  ASSERT_EQ(1, start_tag->attributes.length);

  GumboAttribute* jsif =
      static_cast<GumboAttribute*>(start_tag->attributes.data[0]);
  EXPECT_STREQ("jsif", jsif->name);
  EXPECT_EQ("jsif", ToString(jsif->original_name));
  EXPECT_STREQ("foo && bar", jsif->value);
  EXPECT_EQ("\"foo && bar\"", ToString(jsif->original_value));
  AtEnd();
}

TEST_F(GumboTokenizerTest, MatchedTagPair) {
  SetInput("<div id=dash<-Dash data-test=\"bar\">a</div>");
  NextStartTag(GUMBO_TAG_DIV, true);
  Error(GUMBO_ERR_UNEXPECTED_CHARACTER_IN_UNQUOTED_ATTRIBUTE_VALUE);
  EXPECT_EQ(0, token_.position.offset);

  GumboTokenStartTag* start_tag = &token_.v.start_tag;
  EXPECT_FALSE(start_tag->is_self_closing);
  ASSERT_EQ(2, start_tag->attributes.length);

  GumboAttribute* id =
      static_cast<GumboAttribute*>(start_tag->attributes.data[0]);
  EXPECT_STREQ("id", id->name);
  EXPECT_EQ("id", ToString(id->original_name));
  EXPECT_EQ(1, id->name_start.line);
  EXPECT_EQ(5, id->name_start.offset);
  EXPECT_EQ(6, id->name_start.column);
  EXPECT_EQ(8, id->name_end.column);
  EXPECT_STREQ("dash<-Dash", id->value);
  EXPECT_EQ("dash<-Dash", ToString(id->original_value));
  EXPECT_EQ(9, id->value_start.column);
  EXPECT_EQ(19, id->value_end.column);

  GumboAttribute* data_attr =
      static_cast<GumboAttribute*>(start_tag->attributes.data[1]);
  EXPECT_STREQ("data-test", data_attr->name);
  EXPECT_EQ("data-test", ToString(data_attr->original_name));
  EXPECT_EQ(20, data_attr->name_start.column);
  EXPECT_EQ(29, data_attr->name_end.column);
  EXPECT_STREQ("bar", data_attr->value);
  EXPECT_EQ("\"bar\"", ToString(data_attr->original_value));
  EXPECT_EQ(30, data_attr->value_start.column);
  EXPECT_EQ(35, data_attr->value_end.column);

  NextChar('a');
  EXPECT_EQ(35, token_.position.offset);
  NextEndTag(GUMBO_TAG_DIV);
  AtEnd();
}

TEST_F(GumboTokenizerTest, BogusEndTag) {
  // According to the spec, the correct parse of this is an end tag token for
  // "<div<>" (notice the ending bracket) with the attribute "th=th" (ignored
  // because end tags don't take attributes).
  SetInput("</div</th>");
  NextEndTag(GUMBO_TAG_UNKNOWN, true);
  Error(GUMBO_ERR_UNEXPECTED_SOLIDUS_IN_TAG);
  Error(GUMBO_ERR_END_TAG_WITH_ATTRIBUTES);
  EXPECT_STREQ("div<", token_.v.end_tag.name);
  EXPECT_EQ(0, token_.position.offset);
  EXPECT_EQ("</div</th>", ToString(token_.original_text));
}

TEST_F(GumboTokenizerTest, Whitespace) {
  SetInput("&nbsp;");
  NextChar(0xa0);
  AtEnd();
}

TEST_F(GumboTokenizerTest, NumericHex) {
  SetInput("&#x12ab;");
  NextChar(0x12ab);
  AtEnd();
}

TEST_F(GumboTokenizerTest, NumericDecimal) {
  SetInput("&#1234;");
  NextChar(1234);
  AtEnd();
}

TEST_F(GumboTokenizerTest, NumericInvalidDigit) {
  SetInput("&#google");
  NextChar('&', true);
  Error(GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE);
  NextChar('#');
  NextChar('g');
  NextChar('o');
  NextChar('o');
  NextChar('g');
  NextChar('l');
  NextChar('e');
  AtEnd();
}

TEST_F(GumboTokenizerTest, NumericNoSemicolon) {
  SetInput("&#1234google");
  NextChar(1234, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  NextChar('g');
  NextChar('o');
  NextChar('o');
  NextChar('g');
  NextChar('l');
  NextChar('e');
  AtEnd();
}

TEST_F(GumboTokenizerTest, NamedReplacement) {
  SetInput("&lt;");
  NextChar('<');
  AtEnd();
}

TEST_F(GumboTokenizerTest, NamedReplacementNoSemicolon) {
  SetInput("&gt");
  NextChar('>', true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  AtEnd();
}

TEST_F(GumboTokenizerTest, NamedReplacementWithInvalidUtf8) {
  SetInput("&\xc3\xa5");
  NextChar('&');
  NextChar(229);
  AtEnd();
}

TEST_F(GumboTokenizerTest, NamedReplacementInvalid) {
  SetInput("&google;");
  // This is an error on the semicolon since that's where the error occurs in
  // the spec. Anything other than a semicolon would cause no error.
  NextChar('&');
  NextChar('g');
  NextChar('o');
  NextChar('o');
  NextChar('g');
  NextChar('l');
  NextChar('e');
  NextChar(';', true);
  Error(GUMBO_ERR_UNKNOWN_NAMED_CHARACTER_REFERENCE);
  AtEnd();
}

TEST_F(GumboTokenizerTest, NamedReplacementInvalidNoSemicolon) {
  SetInput("&google");
  NextChar('&');
  NextChar('g');
  NextChar('o');
  NextChar('o');
  NextChar('g');
  NextChar('l');
  NextChar('e');
  AtEnd();
}

TEST_F(GumboTokenizerTest, InAttribute) {
  SetInput("<span foo=\"&noted\"></span>");
  NextStartTag(GUMBO_TAG_SPAN);
  GumboTokenStartTag* start_tag = &token_.v.start_tag;
  ASSERT_EQ(1, start_tag->attributes.length);
  GumboAttribute* attr = static_cast<GumboAttribute*>(start_tag->attributes.data[0]);
  EXPECT_STREQ("&noted", attr->value);
  NextEndTag(GUMBO_TAG_SPAN);
  AtEnd();
}

TEST_F(GumboTokenizerTest, MultiChars) {
  SetInput("&notindot;");
  NextChar(0x22F5);
  NextChar(0x0338);
  AtEnd();
}

TEST_F(GumboTokenizerTest, CharAfter) {
  SetInput("&lt;x");
  NextChar('<');
  NextChar('x');
  AtEnd();
}

TEST_F(GumboTokenizerTest, MaxNumericCharRef) {
  SetInput("FOO&#x10FFFF;ZOO");
  NextChar('F');
  NextChar('O');
  NextChar('O');
  NextChar(0x10FFFF, true);
  Error(GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE);
  NextChar('Z');
  NextChar('O');
  NextChar('O');
  AtEnd();
}

TEST_F(GumboTokenizerTest, InvalidRef) {
  SetInput("ZZ&prod_id=23");
  NextChar('Z');
  NextChar('Z');
  NextChar('&');
  NextChar('p');
  NextChar('r');
  NextChar('o');
  NextChar('d');
  NextChar('_');
  NextChar('i');
  NextChar('d');
  NextChar('=');
  NextChar('2');
  NextChar('3');
  AtEnd();
}

TEST_F(GumboTokenizerTest, InvalidRefInAttr) {
  SetInput("<span foo='ZZ&prod_id=23'></span>");
  NextStartTag(GUMBO_TAG_SPAN);
  GumboTokenStartTag* start_tag = &token_.v.start_tag;
  ASSERT_EQ(1, start_tag->attributes.length);
  GumboAttribute* attr = static_cast<GumboAttribute*>(start_tag->attributes.data[0]);
  EXPECT_STREQ("ZZ&prod_id=23", attr->value);
  NextEndTag(GUMBO_TAG_SPAN);
  AtEnd();
}

TEST_F(GumboTokenizerTest, NumericTooLarge) {
  SetInput("&#x100000030;");
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_CHARACTER_REFERENCE_OUTSIDE_UNICODE_RANGE);
  AtEnd();
}

TEST_F(GumboTokenizerTest, CdataWithBrackets) {
  SetInput("<![CDATA[x]]]]]>y");
  Foreign();
  Next();
  EXPECT_EQ(GUMBO_TOKEN_CDATA, token_.type);
  EXPECT_EQ('x', token_.v.character);
  EXPECT_EQ(10, token_.position.column);
  EXPECT_EQ(1, token_.position.line);
  EXPECT_EQ(9, token_.position.offset);

  Next();
  EXPECT_EQ(GUMBO_TOKEN_CDATA, token_.type);
  EXPECT_EQ(']', token_.v.character);
  EXPECT_EQ(11, token_.position.column);
  EXPECT_EQ(1, token_.position.line);
  EXPECT_EQ(10, token_.position.offset);

  Next();
  EXPECT_EQ(GUMBO_TOKEN_CDATA, token_.type);
  EXPECT_EQ(']', token_.v.character);
  EXPECT_EQ(12, token_.position.column);
  EXPECT_EQ(1, token_.position.line);
  EXPECT_EQ(11, token_.position.offset);

  Next();
  EXPECT_EQ(GUMBO_TOKEN_CDATA, token_.type);
  EXPECT_EQ(']', token_.v.character);
  EXPECT_EQ(13, token_.position.column);
  EXPECT_EQ(1, token_.position.line);
  EXPECT_EQ(12, token_.position.offset);

  NextChar('y');
  EXPECT_EQ(17, token_.position.column);
  EXPECT_EQ(1, token_.position.line);
  EXPECT_EQ(16, token_.position.offset);
  AtEnd();
}

TEST_F(GumboTokenizerTest, EscapedScriptStates) {
  SetInput("<script><!--<script/></script></script>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('/');
  NextChar('>');
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, EscapedScriptStates2) {
  SetInput("<script><!--<script>--></script>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('-');
  NextChar('-');
  NextChar('>');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ReadOutOfBounds) {
  SetInput("&notindot;", 6);
  NextChar(0x00AC, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  NextChar('i');
  NextChar('n');
  AtEnd();
}

TEST_F(GumboTokenizerTest, ControlCharRefs) {
  SetInput("&#x80;&#x82;&#x83;&#x84;&#x85;&#x86;&#x87;&#x88;&#x89;"
           "&#x8A;&#x8B;&#x8C;&#x8E;&#x91;&#x92;&#x93;&#x94;&#x95;"
           "&#x96;&#x97;&#x98;&#x99;&#x9A;&#x9B;&#x9C;&#x9E;&#x9F;");
  NextChar(0x20AC, true);
  NextChar(0x201A, true);
  NextChar(0x0192, true);
  NextChar(0x201E, true);
  NextChar(0x2026, true);
  NextChar(0x2020, true);
  NextChar(0x2021, true);
  NextChar(0x02C6, true);
  NextChar(0x2030, true);
  NextChar(0x0160, true);
  NextChar(0x2039, true);
  NextChar(0x0152, true);
  NextChar(0x017D, true);
  NextChar(0x2018, true);
  NextChar(0x2019, true);
  NextChar(0x201C, true);
  NextChar(0x201D, true);
  NextChar(0x2022, true);
  NextChar(0x2013, true);
  NextChar(0x2014, true);
  NextChar(0x02DC, true);
  NextChar(0x2122, true);
  NextChar(0x0161, true);
  NextChar(0x203A, true);
  NextChar(0x0153, true);
  NextChar(0x017E, true);
  NextChar(0x0178, true);
  for (int i = 0; i < 27; ++i)
    Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  AtEnd();
}

// The tests below here are designed to test all of the tokenizers
// transitions. The name of each test has a specific form (for the most part):
//   StartState_Rule1_Rule2_..._Rulen
// The parser sets the tokenizer in just a handful of states: plaintext,
// rawtext, rcdata, script data, and data. The tests are divided into those 5
// categories and should cover every possible transition from each state.
// (Some transitions are covered more than once, and I'm sure some transitions
// are missing and should be added when found.)
//
// When a character is reconsumed in a new state, the test name _should_
// include which rule gets matched for the new state, but not all of them do.
// That's just an oversight and should be fixed for consistency.
//
// Many states require additional characters in order to emit a token (or do
// so without an error). The rules used to match those tokens are omitted from
// the state name.

// Starting in the PLAINTEXT state
TEST_F(GumboTokenizerTest, Plaintext_NULL) {
  SetInput("", 1);
  SetState(GUMBO_LEX_PLAINTEXT);
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
}

TEST_F(GumboTokenizerTest, Plaintext_EOF) {
  SetInput("");
  SetState(GUMBO_LEX_PLAINTEXT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Plaintext_AnythingElse) {
  SetInput("<plaintext>a\xce\xb2\xd7\x92</plaintext>&not;");
  NextStartTag(GUMBO_TAG_PLAINTEXT);
  SetState(GUMBO_LEX_PLAINTEXT);
  NextChar(0x61);
  NextChar(0x03B2);
  NextChar(0x05D2);
  NextChar('<');
  NextChar('/');
  NextChar('p');
  NextChar('l');
  NextChar('a');
  NextChar('i');
  NextChar('n');
  NextChar('t');
  NextChar('e');
  NextChar('x');
  NextChar('t');
  NextChar('>');
  NextChar('&');
  NextChar('n');
  NextChar('o');
  NextChar('t');
  NextChar(';');
}

// Starting in the RAWTEXT state
TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_InappropriateTab) {
  SetInput("<iframe></i\tx");
  NextStartTag(GUMBO_TAG_IFRAME);
  SetState(GUMBO_LEX_RAWTEXT);
  NextChar('<');
  NextChar('/');
  NextChar('i');
  NextSpace('\t');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_InappropriateLF) {
  SetInput("<noframes></n\nx");
  NextStartTag(GUMBO_TAG_NOFRAMES);
  SetState(GUMBO_LEX_RAWTEXT);
  NextChar('<');
  NextChar('/');
  NextChar('n');
  NextSpace('\n');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_InappropriateFF) {
  SetInput("<iframe></i\fx");
  NextStartTag(GUMBO_TAG_IFRAME);
  SetState(GUMBO_LEX_RAWTEXT);
  NextChar('<');
  NextChar('/');
  NextChar('i');
  NextSpace('\f');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_InappropriateSpace) {
  SetInput("<noframes></n x");
  NextStartTag(GUMBO_TAG_NOFRAMES);
  SetState(GUMBO_LEX_RAWTEXT);
  NextChar('<');
  NextChar('/');
  NextChar('n');
  NextSpace(' ');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_InappropriateSlash) {
  SetInput("<iframe></i/x");
  NextStartTag(GUMBO_TAG_IFRAME);
  SetState(GUMBO_LEX_RAWTEXT);
  NextChar('<');
  NextChar('/');
  NextChar('i');
  NextChar('/');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_InappropriateGT) {
  SetInput("<noframes></n>x");
  NextStartTag(GUMBO_TAG_NOFRAMES);
  SetState(GUMBO_LEX_RAWTEXT);
  NextChar('<');
  NextChar('/');
  NextChar('n');
  NextChar('>');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_AppropriateLF) {
  SetInput("<noframes></nofRAmes\n>x");
  NextStartTag(GUMBO_TAG_NOFRAMES);
  SetState(GUMBO_LEX_RAWTEXT);
  NextEndTag(GUMBO_TAG_NOFRAMES);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_AppropriateFF) {
  SetInput("<iframe></ifrAMe\f foo=bar>x");
  NextStartTag(GUMBO_TAG_IFRAME);
  SetState(GUMBO_LEX_RAWTEXT);
  NextEndTag(GUMBO_TAG_IFRAME, true);
  Error(GUMBO_ERR_END_TAG_WITH_ATTRIBUTES);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_AppropriateSpace) {
  SetInput("<noframes></Noframes >x");
  NextStartTag(GUMBO_TAG_NOFRAMES);
  SetState(GUMBO_LEX_RAWTEXT);
  NextEndTag(GUMBO_TAG_NOFRAMES);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_AppropriateSlash_GT) {
  SetInput("<iframe></IFRAME/>x");
  NextStartTag(GUMBO_TAG_IFRAME);
  SetState(GUMBO_LEX_RAWTEXT);
  NextEndTag(GUMBO_TAG_IFRAME, true);
  Error(GUMBO_ERR_END_TAG_WITH_TRAILING_SOLIDUS);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_AppropriateSlash_EOF) {
  SetInput("<iframe></iframe/");
  NextStartTag(GUMBO_TAG_IFRAME);
  SetState(GUMBO_LEX_RAWTEXT);
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_TAG);
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_AppropriateSlash_AnythingElse) {
  SetInput("<iframe></iframe/ >x");
  NextStartTag(GUMBO_TAG_IFRAME);
  SetState(GUMBO_LEX_RAWTEXT);
  NextEndTag(GUMBO_TAG_IFRAME, true);
  Error(GUMBO_ERR_UNEXPECTED_SOLIDUS_IN_TAG);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_AppropriateGT) {
  SetInput("<noframes></noframes>x");
  NextStartTag(GUMBO_TAG_NOFRAMES);
  SetState(GUMBO_LEX_RAWTEXT);
  NextEndTag(GUMBO_TAG_NOFRAMES);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_Alpha_AnythingElse) {
  SetInput("<iframe></if\xce\xb2");
  NextStartTag(GUMBO_TAG_IFRAME);
  SetState(GUMBO_LEX_RAWTEXT);
  NextChar('<');
  NextChar('/');
  NextChar('i');
  NextChar('f');
  NextChar(0x03B2);
}

TEST_F(GumboTokenizerTest, Rawtext_LT_Slash_AnythingElse) {
  SetInput("</0");
  SetState(GUMBO_LEX_RAWTEXT);
  NextChar('<');
  NextChar('/');
  NextChar('0');
}

TEST_F(GumboTokenizerTest, Rawtext_LT_AnythingElse) {
  SetInput("<p>");
  SetState(GUMBO_LEX_RAWTEXT);
  NextChar('<');
  NextChar('p');
  NextChar('>');
}

TEST_F(GumboTokenizerTest, Rawtext_NULL) {
  SetInput("", 1);
  SetState(GUMBO_LEX_RAWTEXT);
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
}

TEST_F(GumboTokenizerTest, Rawtext_EOF) {
  SetInput("");
  SetState(GUMBO_LEX_RAWTEXT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Rawtext_AnythingElse) {
  SetInput("a\xce\xb2\xd7\x92>&not;");
  SetState(GUMBO_LEX_RAWTEXT);
  NextChar(0x61);
  NextChar(0x03B2);
  NextChar(0x05D2);
  NextChar('>');
  NextChar('&');
  NextChar('n');
  NextChar('o');
  NextChar('t');
  NextChar(';');
}

// Starting in the RCDATA state
TEST_F(GumboTokenizerTest, Rcdata_Amp_Alnum_Match_Semicolon) {
  SetInput("&fjlig;x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0x0066);
  NextChar(0x006A);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_Alnum_Match) {
  SetInput("&aacutex");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0x00E1, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_Alnum_Otherwise_Alnum_Semicolon) {
  SetInput("&1f;x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar('&');
  NextChar('1');
  NextChar('f');
  NextChar(';', true);
  Error(GUMBO_ERR_UNKNOWN_NAMED_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_Alnum_Otherwise_Alnum_AnythingElse) {
  SetInput("&1f.x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar('&');
  NextChar('1');
  NextChar('f');
  NextChar('.');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_X_Hex_Semicolon_Zero) {
  SetInput("&#X00;x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_NULL_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_X_Hex_Semicolon_TooLarge) {
  SetInput("&#XABCdef123;x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_CHARACTER_REFERENCE_OUTSIDE_UNICODE_RANGE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_X_Hex_Semicolon_Surrogate) {
  SetInput("&#XDb74;x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_SURROGATE_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_x_Hex_Semicolon_Noncharacter) {
  SetInput("&#xFdD8;x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0xFDD8, true);
  Error(GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_x_Hex_Semicolon_Noncharacter2) {
  SetInput("&#x7FFFE;x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0x7FFFE, true);
  Error(GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_x_Hex_Semicolon_C0Control) {
  SetInput("&#x3;x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(3, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_x_Hex_Semicolon_NL) {
  SetInput("&#x0A;x");
  SetState(GUMBO_LEX_RCDATA);
  NextSpace('\n');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_x_Hex_Semicolon_FF) {
  SetInput("&#x0C;x");
  SetState(GUMBO_LEX_RCDATA);
  NextSpace('\f');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_x_Hex_Semicolon_CR) {
  SetInput("&#x0D;x");
  SetState(GUMBO_LEX_RCDATA);
  NextSpace('\r', true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_X_Hex_Semicolon_Control) {
  SetInput("&#X81;x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0x81, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_x_Hex_Semicolon_Control2) {
  SetInput("&#x82;x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0x201A, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_x_Hex_AnythingElse) {
  SetInput("&#x2f1Ax");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0x2F1A, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_x_Hex_AnythingElse2) {
  SetInput("&#x2f1A-");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0x2F1A, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  NextChar('-');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_x_AnythingElse) {
  SetInput("&#xG");
  SetState(GUMBO_LEX_RCDATA);
  NextChar('&', true);
  Error(GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE);
  NextChar('#');
  NextChar('x');
  NextChar('G');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_AnythingElse_Digit_Semicolon) {
  SetInput("&#1234;x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(1234);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_AnythingElse_Digit_Semicolon_Control) {
  SetInput("&#128;x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0x20AC, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_AnythingElse_Digit_AnythingElse) {
  SetInput("&#1234a");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(1234, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  NextChar('a');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_NumberSign_AnythingElse_Digit_AnythingElse_Control) {
  SetInput("&#128a");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0x20AC, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  NextChar('a');
}

TEST_F(GumboTokenizerTest, Rcdata_Amp_AnythingElse) {
  SetInput("&#x");
  SetState(GUMBO_LEX_RCDATA);
  NextChar('&', true);
  Error(GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE);
  NextChar('#');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_InappropriateTab) {
  SetInput("<title></t\tx");
  NextStartTag(GUMBO_TAG_TITLE);
  SetState(GUMBO_LEX_RCDATA);
  NextChar('<');
  NextChar('/');
  NextChar('t');
  NextSpace('\t');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_InappropriateLF) {
  SetInput("<textarea></t\nx");
  NextStartTag(GUMBO_TAG_TEXTAREA);
  SetState(GUMBO_LEX_RCDATA);
  NextChar('<');
  NextChar('/');
  NextChar('t');
  NextSpace('\n');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_InappropriateFF) {
  SetInput("<title></t\fx");
  NextStartTag(GUMBO_TAG_TITLE);
  SetState(GUMBO_LEX_RCDATA);
  NextChar('<');
  NextChar('/');
  NextChar('t');
  NextSpace('\f');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_InappropriateSpace) {
  SetInput("<textarea></t x");
  NextStartTag(GUMBO_TAG_TEXTAREA);
  SetState(GUMBO_LEX_RCDATA);
  NextChar('<');
  NextChar('/');
  NextChar('t');
  NextSpace(' ');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_InappropriateSlash) {
  SetInput("<title></t/x");
  NextStartTag(GUMBO_TAG_TITLE);
  SetState(GUMBO_LEX_RCDATA);
  NextChar('<');
  NextChar('/');
  NextChar('t');
  NextChar('/');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_InappropriateGT) {
  SetInput("<textarea></t>x");
  NextStartTag(GUMBO_TAG_TEXTAREA);
  SetState(GUMBO_LEX_RCDATA);
  NextChar('<');
  NextChar('/');
  NextChar('t');
  NextChar('>');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_AppropriateLF) {
  SetInput("<textarea></teXTarea\n>x");
  NextStartTag(GUMBO_TAG_TEXTAREA);
  SetState(GUMBO_LEX_RCDATA);
  NextEndTag(GUMBO_TAG_TEXTAREA);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_AppropriateFF) {
  SetInput("<title></titlE\f foo=bar>x");
  NextStartTag(GUMBO_TAG_TITLE);
  SetState(GUMBO_LEX_RCDATA);
  NextEndTag(GUMBO_TAG_TITLE, true);
  Error(GUMBO_ERR_END_TAG_WITH_ATTRIBUTES);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_AppropriateSpace) {
  SetInput("<textarea></Textarea >x");
  NextStartTag(GUMBO_TAG_TEXTAREA);
  SetState(GUMBO_LEX_RCDATA);
  NextEndTag(GUMBO_TAG_TEXTAREA);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_AppropriateSlash_GT) {
  SetInput("<title></TITLE/>x");
  NextStartTag(GUMBO_TAG_TITLE);
  SetState(GUMBO_LEX_RCDATA);
  NextEndTag(GUMBO_TAG_TITLE, true);
  Error(GUMBO_ERR_END_TAG_WITH_TRAILING_SOLIDUS);
  NextChar('x');
}
TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_AppropriateSlash_EOF) {
  SetInput("<title></tITle/");
  NextStartTag(GUMBO_TAG_TITLE);
  SetState(GUMBO_LEX_RCDATA);
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_TAG);
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_AppropriateSlash_AnythingElse) {
  SetInput("<title></title/ >x");
  NextStartTag(GUMBO_TAG_TITLE);
  SetState(GUMBO_LEX_RCDATA);
  NextEndTag(GUMBO_TAG_TITLE, true);
  Error(GUMBO_ERR_UNEXPECTED_SOLIDUS_IN_TAG);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_AppropriateGT) {
  SetInput("<textarea></textarea>x");
  NextStartTag(GUMBO_TAG_TEXTAREA);
  SetState(GUMBO_LEX_RCDATA);
  NextEndTag(GUMBO_TAG_TEXTAREA);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_Alpha_AnythingElse) {
  SetInput("<title></ti\xce\xb2");
  NextStartTag(GUMBO_TAG_TITLE);
  SetState(GUMBO_LEX_RCDATA);
  NextChar('<');
  NextChar('/');
  NextChar('t');
  NextChar('i');
  NextChar(0x03B2);
}

TEST_F(GumboTokenizerTest, Rcdata_LT_Slash_AnythingElse) {
  SetInput("</0");
  SetState(GUMBO_LEX_RCDATA);
  NextChar('<');
  NextChar('/');
  NextChar('0');
}

TEST_F(GumboTokenizerTest, Rcdata_LT_AnythingElse) {
  SetInput("<p>");
  SetState(GUMBO_LEX_RCDATA);
  NextChar('<');
  NextChar('p');
  NextChar('>');
}

TEST_F(GumboTokenizerTest, Rcdata_NULL) {
  SetInput("", 1);
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
}

TEST_F(GumboTokenizerTest, Rcdata_EOF) {
  SetInput("");
  SetState(GUMBO_LEX_RCDATA);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Rcdata_AnythingElse) {
  SetInput("a\xce\xb2\xd7\x92");
  SetState(GUMBO_LEX_RCDATA);
  NextChar(0x61);
  NextChar(0x03B2);
  NextChar(0x05D2);
}

// Starting in the script data state
TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_InappropriateTab) {
  SetInput("<script></s\tx");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextSpace('\t');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_InappropriateLF) {
  SetInput("<script></s\nx");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextSpace('\n');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_InappropriateFF) {
  SetInput("<script></s\fx");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextSpace('\f');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_InappropriateSpace) {
  SetInput("<script></s x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextSpace(' ');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_InappropriateSlash) {
  SetInput("<script></s/x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextChar('/');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_InappropriateGT) {
  SetInput("<script></s>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextChar('>');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_AppropriateLF) {
  SetInput("<script></scRIpt\n>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextEndTag(GUMBO_TAG_SCRIPT);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_AppropriateFF) {
  SetInput("<script></scripT\f foo=bar>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextEndTag(GUMBO_TAG_SCRIPT, true);
  Error(GUMBO_ERR_END_TAG_WITH_ATTRIBUTES);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_AppropriateSpace) {
  SetInput("<script></Script >x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextEndTag(GUMBO_TAG_SCRIPT);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_AppropriateSlash_GT) {
  SetInput("<script></SCRIPT/>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextEndTag(GUMBO_TAG_SCRIPT, true);
  Error(GUMBO_ERR_END_TAG_WITH_TRAILING_SOLIDUS);
  NextChar('x');
}
TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_AppropriateSlash_EOF) {
  SetInput("<script></script/");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_TAG);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_AppropriateSlash_AnythingElse) {
  SetInput("<script></script/ >x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextEndTag(GUMBO_TAG_SCRIPT, true);
  Error(GUMBO_ERR_UNEXPECTED_SOLIDUS_IN_TAG);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_AppropriateGT) {
  SetInput("<script></script>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextEndTag(GUMBO_TAG_SCRIPT);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_Alpha_AnythingElse) {
  SetInput("<script></sc</script>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextChar('c');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Slash_AnythingElse) {
  SetInput("</0");
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('/');
  NextChar('0');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_Dash_LT_Slash_Alpha_InappropriateTab_EOF) {
  SetInput("<script><!---</s\t");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextSpace('\t');
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_InappropriateLF_NULL) {
  SetInput("<script><!--</s\n\x00", sizeof("<script><!--</s\n\x00")-1);
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextSpace('\n');
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_InappropriateFF_AnythingElse) {
  SetInput("<script><!--</s\fx");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextSpace('\f');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_InappropriateSpace) {
  SetInput("<script><!--</s x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextSpace(' ');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_InappropriateSlash) {
  SetInput("<script><!--</s/x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextChar('/');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_InappropriateGT) {
  SetInput("<script><!--</s>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextChar('>');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_AppropriateTab) {
  SetInput("<script><!--</sCrIpT\t>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextEndTag(GUMBO_TAG_SCRIPT);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_AppropriateLF) {
  SetInput("<script><!--</Script\n>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextEndTag(GUMBO_TAG_SCRIPT);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_AppropriateFF) {
  SetInput("<script><!--</SCRIPT\f>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextEndTag(GUMBO_TAG_SCRIPT);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_AppropriateSpace) {
  SetInput("<script><!--</script >x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextEndTag(GUMBO_TAG_SCRIPT);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_AppropriateSlash_GT) {
  SetInput("<script><!--</script/>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextEndTag(GUMBO_TAG_SCRIPT, true);
  Error(GUMBO_ERR_END_TAG_WITH_TRAILING_SOLIDUS);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_AppropriateSlash_EOF) {
  SetInput("<script><!--</script/");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_TAG);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_AppropriateSlash_AnythingElse) {
  SetInput("<script><!--</script/ >x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextEndTag(GUMBO_TAG_SCRIPT, true);
  Error(GUMBO_ERR_UNEXPECTED_SOLIDUS_IN_TAG);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_AppropriateGT) {
  SetInput("<script><!--</scrIPT>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextEndTag(GUMBO_TAG_SCRIPT);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_Alpha_AnythingElse) {
  SetInput("<script><!--</s.x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextChar('.');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Slash_AnythingElse) {
  SetInput("<!--</>");
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('/');
  NextChar('>');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptTab_Dash_Dash_Dash_NULL_EOF) {
  SetInput("<!--<scRIpt\t---\x00", sizeof("<!--<scRIpt\t---\x00")-1);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('R');
  NextChar('I');
  NextChar('p');
  NextChar('t');
  NextSpace('\t');
  NextChar('-');
  NextChar('-');
  NextChar('-');
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_Dash_Dash_LT) {
  SetInput("<script><!--<script>--</script></script>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_Dash_Dash_EOF) {
  SetInput("<script><!--<script>--");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('-');
  NextChar('-');
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_Dash_Dash_AnythingElse) {
  SetInput("<script><!--<script>--X--></script>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('-');
  NextChar('-');
  NextChar('X');
  NextChar('-');
  NextChar('-');
  NextChar('>');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptTab_Dash_NULL) {
  SetInput("<!--<scRIpt\t-\x00", sizeof("<!--<scRIpt\t---\x00")-1);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('R');
  NextChar('I');
  NextChar('p');
  NextChar('t');
  NextSpace('\t');
  NextChar('-');
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_Dash_LT) {
  SetInput("<script><!--<script>-</script></script>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('-');
  NextChar('<');
  NextChar('/');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_Dash_EOF) {
  SetInput("<script><!--<script>-");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('-');
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_Dash_AnythingElse) {
  SetInput("<script><!--<script>-X--></script>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('-');
  NextChar('X');
  NextChar('-');
  NextChar('-');
  NextChar('>');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptNL_LT_Slash_ScriptTab) {
  SetInput("<script><!--<script\n</Script\tx");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextSpace('\n');
  NextChar('<');
  NextChar('/');
  NextChar('S');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextSpace('\t');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptFF_LT_Slash_ScriptNL) {
  SetInput("<script><!--<script\f</Script\nx");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextSpace('\f');
  NextChar('<');
  NextChar('/');
  NextChar('S');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextSpace('\n');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptSpace_LT_Slash_ScriptFF) {
  SetInput("<script><!--<script </Script\fx");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextSpace(' ');
  NextChar('<');
  NextChar('/');
  NextChar('S');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextSpace('\f');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptSlash_LT_Slash_ScriptSpace) {
  SetInput("<script><!--<script/</Script x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('/');
  NextChar('<');
  NextChar('/');
  NextChar('S');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextSpace(' ');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_LT_Slash_ScriptSlash) {
  SetInput("<script><!--<script></Script/x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('<');
  NextChar('/');
  NextChar('S');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('/');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_LT_Slash_ScriptGT) {
  SetInput("<script><!--<script></Script>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('<');
  NextChar('/');
  NextChar('S');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_LT_Slash_Tab) {
  SetInput("<script><!--<script></\t>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('<');
  NextChar('/');
  NextSpace('\t');
  NextChar('>');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_LT_Slash_LF) {
  SetInput("<script><!--<script></\n>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('<');
  NextChar('/');
  NextSpace('\n');
  NextChar('>');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_LT_Slash_FF) {
  SetInput("<script><!--<script></\f>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('<');
  NextChar('/');
  NextSpace('\f');
  NextChar('>');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_LT_Slash_Slash) {
  SetInput("<script><!--<script><//>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('<');
  NextChar('/');
  NextChar('/');
  NextChar('>');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_LT_Slash_AnythingElse) {
  SetInput("<script><!--<script></.>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('<');
  NextChar('/');
  NextChar('.');
  NextChar('>');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_AnythingElse) {
  SetInput("<script><!--<script>x");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_ScriptGT_NULL) {
  SetInput("<script><!--<script>\x00", sizeof("<script><!--<script>\x00")-1);
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('c');
  NextChar('r');
  NextChar('i');
  NextChar('p');
  NextChar('t');
  NextChar('>');
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_Tab_LT_Slash_Alpha_AppropriateTab) {
  SetInput("<script><!--<s\t</SCRIPT\t>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextSpace('\t');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_LF_LT_Slash_Alpha_AppropriateLF) {
  SetInput("<script><!--<s\n</SCRIPT\n>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextSpace('\n');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_FF_LT_Slash_Alpha_AppropriateFF) {
  SetInput("<script><!--<s\f</SCRIPT\f>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextSpace('\f');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_Space_LT_Slash_Alpha_AppropriateSpace) {
  SetInput("<script><!--<s </SCRIPT >");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextSpace(' ');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_Slash_LT_Slash_Alpha_AppropriateSlash) {
  SetInput("<script><!--<s/</SCRIPT/>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('/');
  NextEndTag(GUMBO_TAG_SCRIPT, true);
  Error(GUMBO_ERR_END_TAG_WITH_TRAILING_SOLIDUS);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_GT_LT_Slash_Alpha_AppropriateGT) {
  SetInput("<script><!--<s></SCRIPT>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('>');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_Alpha_AnythingElse_LT_Slash_Alpha_AnythingElse) {
  SetInput("<script><!--<s.</S.");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('s');
  NextChar('.');
  NextChar('<');
  NextChar('/');
  NextChar('S');
  NextChar('.');
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_Dash_LT_AnythingElse_NULL_AnythingElse_EOF) {
  SetInput("<script><!--<\x00.", sizeof("<script><!--<\x00.")-1);
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  NextChar('.');
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_Bang_Dash_AnythingElse) {
  SetInput("<script><!-x</script>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('x');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_Bang_Dash_Dash_LT_AnythingElse_Dash_Dash_NULL_AnythingElse_EOF) {
  SetInput("<script><!--<.--\x00.", sizeof("<script><!--<.--\x00.")-1);
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('<');
  NextChar('.');
  NextChar('-');
  NextChar('-');
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  NextChar('.');
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
}

TEST_F(GumboTokenizerTest, ScriptData_Bang_Dash_Dash_EOF) {
  SetInput("<script><!--");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
}

TEST_F(GumboTokenizerTest, ScriptData_Bang_Dash_Dash_GT_EOF) {
  SetInput("<script><!-->");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('>');
  AtEnd();
}

TEST_F(GumboTokenizerTest, ScriptData_Bang_Dash_Dash_AnythingElse_Dash_LT) {
  SetInput("<script><!--X-<</script>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('X');
  NextChar('-');
  NextChar('<');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_Bang_Dash_Dash_AnythingElse_Dash_NULL) {
  SetInput("<script><!--X-\x00</script>", sizeof("<script><!--X-\x00</script>")-1);
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('X');
  NextChar('-');
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_Bang_Dash_Dash_AnythingElse_Dash_EOF) {
  SetInput("<script><!--X-");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('X');
  NextChar('-');
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
}

TEST_F(GumboTokenizerTest, ScriptData_Bang_Dash_Dash_AnythingElse_Dash_AnythingElse) {
  SetInput("<script><!--X-X</script>");
  NextStartTag(GUMBO_TAG_SCRIPT);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('!');
  NextChar('-');
  NextChar('-');
  NextChar('X');
  NextChar('-');
  NextChar('X');
  NextEndTag(GUMBO_TAG_SCRIPT);
}

TEST_F(GumboTokenizerTest, ScriptData_LT_AnythingElse) {
  SetInput("<p>");
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar('<');
  NextChar('p');
  NextChar('>');
}

TEST_F(GumboTokenizerTest, ScriptData_NULL) {
  SetInput("", 1);
  SetState(GUMBO_LEX_SCRIPT_DATA);
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
}

TEST_F(GumboTokenizerTest, Data_Amp_Alnum_Otherwise_Alnum_Semicolon) {
  SetInput("&1f;x");
  NextChar('&');
  NextChar('1');
  NextChar('f');
  NextChar(';', true);
  Error(GUMBO_ERR_UNKNOWN_NAMED_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_Alnum_Otherwise_Alnum_AnythingElse) {
  SetInput("&1f.x");
  NextChar('&');
  NextChar('1');
  NextChar('f');
  NextChar('.');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_X_Hex_Semicolon_Zero) {
  SetInput("&#X00;x");
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_NULL_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_X_Hex_Semicolon_TooLarge) {
  SetInput("&#XABCdef123;x");
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_CHARACTER_REFERENCE_OUTSIDE_UNICODE_RANGE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_X_Hex_Semicolon_Surrogate) {
  SetInput("&#XDb74;x");
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_SURROGATE_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_x_Hex_Semicolon_Noncharacter) {
  SetInput("&#xFdD8;x");
  NextChar(0xFDD8, true);
  Error(GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_x_Hex_Semicolon_Noncharacter2) {
  SetInput("&#x7FFFE;x");
  NextChar(0x7FFFE, true);
  Error(GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_x_Hex_Semicolon_C0Control) {
  SetInput("&#x3;x");
  NextChar(3, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_x_Hex_Semicolon_NL) {
  SetInput("&#x0A;x");
  NextSpace('\n');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_x_Hex_Semicolon_FF) {
  SetInput("&#x0C;x");
  NextSpace('\f');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_x_Hex_Semicolon_CR) {
  SetInput("&#x0D;x");
  NextSpace('\r', true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_X_Hex_Semicolon_Control) {
  SetInput("&#X81;x");
  NextChar(0x81, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_x_Hex_Semicolon_Control2) {
  SetInput("&#x82;x");
  NextChar(0x201A, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_x_Hex_AnythingElse) {
  SetInput("&#x2f1Ax");
  NextChar(0x2F1A, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_x_Hex_AnythingElse2) {
  SetInput("&#x2f1A-");
  NextChar(0x2F1A, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  NextChar('-');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_x_AnythingElse) {
  SetInput("&#xG");
  NextChar('&', true);
  Error(GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE);
  NextChar('#');
  NextChar('x');
  NextChar('G');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_AnythingElse_Digit_Semicolon) {
  SetInput("&#1234;x");
  NextChar(1234);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_AnythingElse_Digit_Semicolon_TooLarge) {
  SetInput("&#1234567890;x");
  NextChar(0xFFFD, true);
  Error(GUMBO_ERR_CHARACTER_REFERENCE_OUTSIDE_UNICODE_RANGE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_AnythingElse_Digit_Semicolon_Control) {
  SetInput("&#128;x");
  NextChar(0x20AC, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_AnythingElse_Digit_AnythingElse) {
  SetInput("&#1234a");
  NextChar(1234, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  NextChar('a');
}

TEST_F(GumboTokenizerTest, Data_Amp_NumberSign_AnythingElse_Digit_AnythingElse_Control) {
  SetInput("&#128a");
  NextChar(0x20AC, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  NextChar('a');
}

TEST_F(GumboTokenizerTest, Data_Amp_AnythingElse) {
  SetInput("&#x");
  NextChar('&', true);
  Error(GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE);
  NextChar('#');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_Dash_Dash_GT) {
  SetInput("<!---->");
  NextComment("");
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_Dash_Dash_Bang_Dash_EOF) {
  SetInput("<!----!-");
  NextComment("--!", true);
  Error(GUMBO_ERR_EOF_IN_COMMENT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_Dash_Dash_Bang_GT) {
  SetInput("<!----!>");
  NextComment("", true);
  Error(GUMBO_ERR_INCORRECTLY_CLOSED_COMMENT);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_Dash_Dash_Bang_EOF) {
  SetInput("<!----!");
  NextComment("", true);
  Error(GUMBO_ERR_EOF_IN_COMMENT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_Dash_Dash_Bang_AnythingElse_AnythingElse_Dash_EOF) {
  SetInput("<!----!x-");
  NextComment("--!x", true);
  Error(GUMBO_ERR_EOF_IN_COMMENT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_Dash_Dash_Dash_EOF) {
  SetInput("<!-----");
  NextComment("-", true);
  Error(GUMBO_ERR_EOF_IN_COMMENT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_Dash_Dash_AnythingElse_AnythingElse_EOF) {
  SetInput("<!----x");
  NextComment("--x", true);
  Error(GUMBO_ERR_EOF_IN_COMMENT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_Dash_GT) {
  SetInput("<!--->");
  NextComment("", true);
  Error(GUMBO_ERR_ABRUPT_CLOSING_OF_EMPTY_COMMENT);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_Dash_EOF) {
  SetInput("<!---");
  NextComment("", true);
  Error(GUMBO_ERR_EOF_IN_COMMENT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_Dash_AnythingElse) {
  SetInput("<!---x-->");
  NextComment("-x");
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_GT) {
  SetInput("<!-->");
  NextComment("", true);
  Error(GUMBO_ERR_ABRUPT_CLOSING_OF_EMPTY_COMMENT);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_AnythingElse_LT_Bang_Dash_Dash_GT_GT) {
  SetInput("<!--<!-->");
  NextComment("<!");
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_AnythingElse_LT_Bang_Dash_Dash_EOF) {
  SetInput("<!--<!--");
  NextComment("<!", true);
  Error(GUMBO_ERR_EOF_IN_COMMENT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_AnythingElse_LT_Bang_Dash_Dash_AnythingElse) {
  SetInput("<!--<!--x-->");
  NextComment("<!--x", true);
  Error(GUMBO_ERR_NESTED_COMMENT);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_AnythingElse_LT_Bang_Dash_AnythingElse) {
  SetInput("<!--<!-x-->");
  NextComment("<!-x");
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_AnythingElse_LT_Bang_AnythingElse) {
  SetInput("<!--<!x-->");
  NextComment("<!x");
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_AnythingElse_LT_LT_AnythingElse) {
  SetInput("<!--<<-->");
  NextComment("<<");
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_Dash_AnythingElse_AnythingElse_NULL) {
  SetInput("<!---x\x00-->", sizeof("<!---x\x00-->") - 1);
  NextComment("-x\xEF\xBF\xBD", true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_DashDash_AnythingElse_AnythingElse_NULL_EOF) {
  SetInput("<!--0\x00", sizeof("<!--0\x00")-1);
  NextComment("0\xEF\xBF\xBD", true); // Two errors.
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  Error(GUMBO_ERR_EOF_IN_COMMENT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Tab_Tab_LF_FF_Space_Alpha_Tab_Tab_LF_FF_Space_GT) {
  SetInput("<!DoCtyPE\t\t\n\f H\t\t\n\f >");
  NextDoctype("h", NULL, NULL);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_LF_Tab_LF_FF_Space_Alpha_LF_Tab_LF_FF_Space_GT) {
  SetInput("<!DoCtyPE\n\t\n\f H\n\t\n\f >");
  NextDoctype("h", NULL, NULL);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_FF_Tab_LF_FF_Space_Alpha_FF_Tab_LF_FF_Space_GT) {
  SetInput("<!DoCtyPE\f\t\n\f H\f\t\n\f >");
  NextDoctype("h", NULL, NULL);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Tab_LF_FF_Space_Alpha_Space_Tab_LF_FF_Space_GT) {
  SetInput("<!DoCtyPE \t\n\f H \t\n\f >");
  NextDoctype("h", NULL, NULL);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_NULL_GT) {
  SetInput("<!DOCTYPE \x00>", sizeof("<!DOCTYPE \x00>")-1);
  NextDoctype("\xEF\xBF\xBD", NULL, NULL, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_GT) {
  SetInput("<!DOCTYPE >");
  NextDoctype(NULL, NULL, NULL, true);
  Error(GUMBO_ERR_MISSING_DOCTYPE_NAME);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_EOF) {
  SetInput("<!DOCTYPE ");
  NextDoctype(NULL, NULL, NULL, true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_AnythingElse_NULL) {
  SetInput("<!doctype ht\x00ml>", sizeof("<!doctype ht\x00ml>")-1);
  NextDoctype("ht\xEF\xBF\xBDml", NULL, NULL, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_AnythingElse_EOF) {
  SetInput("<!doctype html");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_EOF) {
  SetInput("<!DOCtype HTML ");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Tab_Tab_LF_FF_Space_Quote_Quote_Tab_Tab_LF_FF_Space_GT) {
  SetInput("<!docTYPE HTML PUBLIC\t\t\n\f \"\"\t\t\n\f >");
  NextDoctype("html", "", NULL);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_LF_Tab_LF_FF_Space_Quote_Quote_LF_Tab_LF_FF_Space_GT) {
  SetInput("<!docTYPE HTML PUBLIC\n\t\n\f \"\"\n\t\n\f >");
  NextDoctype("html", "", NULL);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_FF_Tab_LF_FF_Space_Quote_Quote_FF_Tab_LF_FF_Space_GT) {
  SetInput("<!docTYPE HTML PUBLIC\f\t\n\f \"\"\f\t\n\f >");
  NextDoctype("html", "", NULL);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Tab_LF_FF_Space_Quote_Quote_Space_Tab_LF_FF_Space_GT) {
  SetInput("<!docTYPE HTML PUBLIC \t\n\f \"\" \t\n\f >");
  NextDoctype("html", "", NULL);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Space_Quote_Quote_Tab_LF_FF_Space_GT) {
  SetInput("<!DOCTYPE html pubLIC \"\" \"\"\t\n\f >");
  NextDoctype("html", "", "");
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Space_Quote_Quote_EOF) {
  SetInput("<!DOCTYPE html pubLIC \"\" \"\"");
  NextDoctype("html", "", "", true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Space_Quote_Quote_AnythingElse_GT) {
  SetInput("<!DOCTYPE html public \"\" \"\"x>");
  NextDoctype("html", "", "", true);
  Error(GUMBO_ERR_UNEXPECTED_CHARACTER_AFTER_DOCTYPE_SYSTEM_IDENTIFIER);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Space_Quote_Quote_AnythingElse_NULL_GT) {
  SetInput("<!DOCTYPE html public \"\" \"\"\x00>", sizeof("<!DOCTYPE html public \"\" \"\"\x00>")-1);
  NextDoctype("html", "", "", true); // Two errors!
  Error(GUMBO_ERR_UNEXPECTED_CHARACTER_AFTER_DOCTYPE_SYSTEM_IDENTIFIER);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Space_Quote_Quote_AnythingElse_EOF) {
  SetInput("<!DOCTYPE html public \"\" \"\"x");
  NextDoctype("html", "", "", true); // Only one error.
  Error(GUMBO_ERR_UNEXPECTED_CHARACTER_AFTER_DOCTYPE_SYSTEM_IDENTIFIER);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Space_Quote_NULL) {
  SetInput("<!DOCTYPE html public \"\" \"\x00\">", sizeof("<!DOCTYPE html public \"\" \"\x00\">")-1);
  NextDoctype("html", "", "\xEF\xBF\xBD", true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Space_Quote_GT) {
  SetInput("<!DOCTYPE html public \"\" \">");
  NextDoctype("html", "", "", true);
  Error(GUMBO_ERR_ABRUPT_DOCTYPE_SYSTEM_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Space_Quote_EOF) {
  SetInput("<!DOCTYPE html public \"\" \"");
  NextDoctype("html", "", "", true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Space_Quote_AnythingElse) {
  SetInput("<!DOCTYPE html public \"\" \"SyS\">");
  NextDoctype("html", "", "SyS");
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Space_Apos_AnythingElse) {
  SetInput("<!DOCTYPE html public \"\" 'sys'>");
  NextDoctype("html", "", "sys");
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Space_EOF) {
  SetInput("<!DOCTYPE html public \"\" ");
  NextDoctype("html", "", NULL, true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Space_AnythingElse) {
  SetInput("<!DOCTYPE html public \"\" x>z");
  NextDoctype("html", "", NULL, true);
  Error(GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_SYSTEM_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_GT) {
  SetInput("<!DOCTYPE html public \"\">");
  NextDoctype("html", "", NULL);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Quote_Quote) {
  SetInput("<!DOCTYPE html public \"\"\"\">");
  NextDoctype("html", "", "", true);
  Error(GUMBO_ERR_MISSING_WHITESPACE_BETWEEN_DOCTYPE_PUBLIC_AND_SYSTEM_IDENTIFIERS);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_Apos) {
  SetInput("<!DOCTYPE html public \"\"''>");
  NextDoctype("html", "", "", true);
  Error(GUMBO_ERR_MISSING_WHITESPACE_BETWEEN_DOCTYPE_PUBLIC_AND_SYSTEM_IDENTIFIERS);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_EOF) {
  SetInput("<!DOCTYPE html public \"\"");
  NextDoctype("html", "", NULL, true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_Quote_AnythingElse) {
  SetInput("<!DOCTYPE html public \"\"x>");
  NextDoctype("html", "", NULL, true);
  Error(GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_SYSTEM_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_NULL) {
  SetInput("<!DOCTYPE html public \"\x00\">", sizeof("<!DOCTYPE html public \"\x00\">")-1);
  NextDoctype("html", "\xEF\xBF\xBD", NULL, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_GT) {
  SetInput("<!DOCTYPE html public \">");
  NextDoctype("html", "", NULL, true);
  Error(GUMBO_ERR_ABRUPT_DOCTYPE_PUBLIC_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Quote_EOF) {
  SetInput("<!DOCTYPE html public \"foo");
  NextDoctype("html", "foo", NULL, true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Apos_Apos) {
  SetInput("<!DOCTYPE html public ''>");
  NextDoctype("html", "", NULL);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Apos_NULL) {
  SetInput("<!DOCTYPE html public '\x00'>", sizeof("<!DOCTYPE html public '\x00'>")-1);
  NextDoctype("html", "\xEF\xBF\xBD", NULL, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Apos_GT) {
  SetInput("<!DOCTYPE html public 'foo>");
  NextDoctype("html", "foo", NULL, true);
  Error(GUMBO_ERR_ABRUPT_DOCTYPE_PUBLIC_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_Apos_EOF) {
  SetInput("<!DOCTYPE html public 'foo");
  NextDoctype("html", "foo", NULL, true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_GT) {
  SetInput("<!DOCTYPE HTML PUblic >");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_MISSING_DOCTYPE_PUBLIC_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_EOF) {
  SetInput("<!DOCTYPE HTML PUblic ");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Space_AnythingElse) {
  SetInput("<!DOCTYPE HTML PUblic x>");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_PUBLIC_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Quote) {
  SetInput("<!DOCTYPE html public\"foo\">");
  NextDoctype("html", "foo", NULL, true);
  Error(GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_PUBLIC_KEYWORD);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_Apos) {
  SetInput("<!DOCTYPE html public''>");
  NextDoctype("html", "", NULL, true);
  Error(GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_PUBLIC_KEYWORD);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_GT) {
  SetInput("<!DOCTYPE html public>");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_MISSING_DOCTYPE_PUBLIC_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_EOF) {
  SetInput("<!DOCTYPE html public");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Public_AnythingElse) {
  SetInput("<!DOCTYPE html publicX>");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_PUBLIC_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_Tab_Tab_LF_FF_Space_Quote_Quote_GT) {
  SetInput("<!DOCTYPE HtMl SySTem\t\t\n\f \"\">");
  NextDoctype("html", NULL, "");
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_LF_Apos_Apos_GT) {
  SetInput("<!docTYPE hTmL sYstEM\n''>");
  NextDoctype("html", NULL, "");
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_FF_Apos_Apos_GT) {
  SetInput("<!docTYPE hTmL sYstEM\f''>");
  NextDoctype("html", NULL, "");
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_Space_Apos_NULL) {
  SetInput("<!DOCTYPE html SYSTEM '\x00'>", sizeof("<!DOCTYPE html SYSTEM '\x00'>")-1);
  NextDoctype("html", NULL, "\xEF\xBF\xBD", true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_Space_Apos_GT) {
  SetInput("<!DOCTYPE html SYSTEM '>");
  NextDoctype("html", NULL, "", true);
  Error(GUMBO_ERR_ABRUPT_DOCTYPE_SYSTEM_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_Space_Apos_EOF) {
  SetInput("<!DOCTYPE html SYSTEM '");
  NextDoctype("html", NULL, "", true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_Space_GT) {
  SetInput("<!docTYPE hTmL sYstEM >");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_MISSING_DOCTYPE_SYSTEM_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_Space_EOF) {
  SetInput("<!docTYPE hTmL sYstEM ");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_Space_AnythingElse) {
  SetInput("<!docTYPE hTmL sYstEM x>z");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_SYSTEM_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_Quote) {
  SetInput("<!DOCTYPE foo system\"bar\">z");
  NextDoctype("foo", NULL, "bar", true);
  Error(GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_SYSTEM_KEYWORD);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_Apos) {
  SetInput("<!DOCTYPE foo system'bar'>z");
  NextDoctype("foo", NULL, "bar", true);
  Error(GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_SYSTEM_KEYWORD);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_GT) {
  SetInput("<!DOCTYPE foo system>z");
  NextDoctype("foo", NULL, NULL, true);
  Error(GUMBO_ERR_MISSING_DOCTYPE_SYSTEM_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_EOF) {
  SetInput("<!DOCTYPE foo system");
  NextDoctype("foo", NULL, NULL, true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_System_AnythingElse) {
  SetInput("<!DOCTYPE foo systemX>z");
  NextDoctype("foo", NULL, NULL, true);
  Error(GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_SYSTEM_IDENTIFIER);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_Space_Bogus) {
  SetInput("<!DOCTYPE html foobar>z");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_INVALID_CHARACTER_SEQUENCE_AFTER_DOCTYPE_NAME);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_GT) {
  SetInput("<!DOCTYPE html>z");
  NextDoctype("html", NULL, NULL);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_NULL) {
  SetInput("<!DOCTYPE html\x00>z", sizeof("<!DOCTYPE html\x00>z")-1);
  NextDoctype("html\xEF\xBF\xBD", NULL, NULL, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_Alpha_EOF) {
  SetInput("<!DOCTYPE html");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_Space_NULL) {
  SetInput("<!DOCTYPE \x00>z", sizeof("<!DOCTYPE \x00>z")-1);
  NextDoctype("\xEF\xBF\xBD", NULL, NULL, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_GT) {
  SetInput("<!DOCtype>z");
  NextDoctype(NULL, NULL, NULL, true);
  Error(GUMBO_ERR_MISSING_DOCTYPE_NAME);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_EOF) {
  SetInput("<!DOCTYPE");
  NextDoctype(NULL, NULL, NULL, true);
  Error(GUMBO_ERR_EOF_IN_DOCTYPE);
  EXPECT_TRUE(token_.v.doc_type.force_quirks);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Doctype_AnythingElse) {
  SetInput("<!DOCTYPEhtml>z");
  NextDoctype("html", NULL, NULL, true);
  Error(GUMBO_ERR_MISSING_WHITESPACE_BEFORE_DOCTYPE_NAME);
  EXPECT_FALSE(token_.v.doc_type.force_quirks);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Cdata_Bracket_Bracket_Bracket_GT) {
  SetInput("<![CDATA[]]]>x");
  Foreign();
  NextCdata(']');
  NextChar('x');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Cdata_Bracket_Bracket_AnythingElse) {
  SetInput("<![CDATA[]]x]]>z");
  Foreign();
  NextCdata(']');
  NextCdata(']');
  NextCdata('x');
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Cdata_Bracket_AnythingElse) {
  SetInput("<![CDATA[]>x]]>z");
  Foreign();
  NextCdata(']');
  NextCdata('>');
  NextCdata('x');
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Cdata_AnythingElse_EOF) {
  SetInput("<![CDATA[x");
  Foreign();
  NextCdata('x');
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_CDATA);
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_CdataHtml_GT) {
  SetInput("<![CDATA[bogus>z");
  NextComment("[CDATA[bogus", true);
  Error(GUMBO_ERR_CDATA_IN_HTML_CONTENT);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_CdataHtml_EOF) {
  SetInput("<![CDATA[bogus");
  NextComment("[CDATA[bogus", true);
  Error(GUMBO_ERR_CDATA_IN_HTML_CONTENT);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_Cdata_Html_NULL_AnythingElse) {
  SetInput("<![CDATA[bogus\x00""comment>z", sizeof("<![CDATA[bogus\x00""comment>z")-1);
  NextComment("[CDATA[bogus\xEF\xBF\xBD""comment", true); // Two errors.
  Error(GUMBO_ERR_CDATA_IN_HTML_CONTENT);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Bang_AnythingElse) {
  SetInput("<!4asdf>z");
  NextComment("4asdf", true);
  Error(GUMBO_ERR_INCORRECTLY_OPENED_COMMENT);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Slash_Alpha_Tab_Tab_Slash_Slash_GT) {
  SetInput("</p\t\t/>z");
  NextEndTag(GUMBO_TAG_P, true);
  Error(GUMBO_ERR_END_TAG_WITH_TRAILING_SOLIDUS);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Slash_Alpha_LF_LF_Slash_Slash_EOF) {
  SetInput("</p\n\n/");
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_TAG);
}

TEST_F(GumboTokenizerTest, Data_LT_Slash_Alpha_FF_FF_GT) {
  SetInput("</p\f\f>z");
  NextEndTag(GUMBO_TAG_P);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Slash_Alpha_Space_Space_GT) {
  SetInput("</p  >z");
  NextEndTag(GUMBO_TAG_P);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Slash_Alpha_Space_Alpha_EQ_Alpha_GT) {
  SetInput("</span foo=bar>z");
  NextEndTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_END_TAG_WITH_ATTRIBUTES);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Slash_GT) {
  SetInput("</>z");
  NextChar('z', true);
  Error(GUMBO_ERR_MISSING_END_TAG_NAME);
}

TEST_F(GumboTokenizerTest, Data_LT_Slash_EOF) {
  SetInput("</");
  NextChar('<', true);
  Error(GUMBO_ERR_EOF_BEFORE_TAG_NAME);
  NextChar('/');
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_Slash_AnythingElse) {
  SetInput("</?>z");
  NextComment("?", true);
  Error(GUMBO_ERR_INVALID_FIRST_CHARACTER_OF_TAG_NAME);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Tab_Tab_Slash_Slash_GT) {
  SetInput("<hr\t\t/>z");
  NextStartTag(GUMBO_TAG_HR);
  EXPECT_TRUE(token_.v.start_tag.is_self_closing);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_LF_LF_GT) {
  SetInput("<hr\n\n>z");
  NextStartTag(GUMBO_TAG_HR);
  EXPECT_FALSE(token_.v.start_tag.is_self_closing);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_FF_FF_Slash_Slash_GT) {
  SetInput("<hr\f\f/>z");
  NextStartTag(GUMBO_TAG_HR);
  EXPECT_TRUE(token_.v.start_tag.is_self_closing);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_Space_GT) {
  SetInput("<hr  >z");
  NextStartTag(GUMBO_TAG_HR);
  EXPECT_FALSE(token_.v.start_tag.is_self_closing);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_EOF) {
  SetInput("<span ");
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_TAG);
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_EQ_GT) {
  SetInput("<span =>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_UNEXPECTED_EQUALS_SIGN_BEFORE_ATTRIBUTE_NAME);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("=", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_Tab_Tab_GT) {
  SetInput("<body X\t>z");
  NextStartTag(GUMBO_TAG_BODY);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("x", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_AnythingElse_LF_LF_GT) {
  SetInput("<body ?\n>z");
  NextStartTag(GUMBO_TAG_BODY);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("?", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_AnythingElse_FF_FF_GT) {
  SetInput("<body &$\f>z");
  NextStartTag(GUMBO_TAG_BODY);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("&$", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_Space_Space_GT) {
  SetInput("<body xml:lang >z");
  NextStartTag(GUMBO_TAG_BODY);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("xml:lang", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_Slash_GT) {
  SetInput("<br foo/>z");
  NextStartTag(GUMBO_TAG_BR);
  EXPECT_TRUE(token_.v.start_tag.is_self_closing);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_GT) {
  SetInput("<br foo>z");
  NextStartTag(GUMBO_TAG_BR);
  EXPECT_FALSE(token_.v.start_tag.is_self_closing);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EOF) {
  SetInput("<br foo");
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_TAG);
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Tab_LF_FF_Space_Quote_Quote_Slash) {
  SetInput("<span foo=\t\n\f \"\"/>z");
  NextStartTag(GUMBO_TAG_SPAN);
  EXPECT_TRUE(token_.v.start_tag.is_self_closing);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Tab_LF_FF_Space_Quote_Quote_GT) {
  SetInput("<span foo=\t\n\f \"\">z");
  NextStartTag(GUMBO_TAG_SPAN);
  EXPECT_FALSE(token_.v.start_tag.is_self_closing);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Space_Quote_Quote_EOF) {
  SetInput("<span foo= \"\"");
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_TAG);
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Space_Quote_Quote_AnythingElse) {
  SetInput("<span foo= \"\"bar=''>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_WHITESPACE_BETWEEN_ATTRIBUTES);
  EXPECT_FALSE(token_.v.start_tag.is_self_closing);
  ASSERT_EQ(2, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("", attr->value);

  attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[1]);
  EXPECT_STREQ("bar", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_Alnum_Match_Semicolon) {
  SetInput("<span foo=\"&fjlig;x\">z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\x66\x6Ax", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_Alnum_Match_Alpha) {
  SetInput("<span foo=\"&aacutex\">z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&aacutex", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_Alnum_Match_Num) {
  SetInput("<span foo=\"&aacute0\">z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&aacute0", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_Alnum_Match_EQ) {
  SetInput("<span foo=\"&aacute=\">z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&aacute=", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_Alnum_Match_Otherwise) {
  SetInput("<span foo=\"&aacute\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xC3\xA1", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_Alnum_Otherwise_Alnum_Semicolon) {
  SetInput("<span foo=\"&1f;x\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_UNKNOWN_NAMED_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&1f;x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_Alnum_Otherwise_Alnum_AnythingElse) {
  SetInput("<span foo=\"&1f.x\">z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&1f.x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_X_Hex_Semicolon_Zero) {
  SetInput("<span foo=\"&#X00;x\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_NULL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xBF\xBDx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_X_Hex_Semicolon_TooLarge) {
  SetInput("<span foo=\"&#XABCdefA123;x\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  Error(GUMBO_ERR_CHARACTER_REFERENCE_OUTSIDE_UNICODE_RANGE);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xBF\xBDx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_X_Hex_Semicolon_Surrogate) {
  SetInput("<span foo=\"&#XDb74;x\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_SURROGATE_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xBF\xBDx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_x_Hex_Semicolon_Noncharacter) {
  SetInput("<span foo=\"&#xFdD8;x\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xB7\x98x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_x_Hex_Semicolon_Noncharacter2) {
  SetInput("<span foo=\"&#x7FFFE;x\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xF1\xBF\xBF\xBEx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_x_Hex_Semicolon_C0Control) {
  SetInput("<span foo=\"&#x3;x\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\x03x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_x_Hex_Semicolon_NL) {
  SetInput("<span foo=\"&#x0A;x\">z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\nx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_x_Hex_Semicolon_FF) {
  SetInput("<span foo=\"&#x0C;x\">z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\fx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_x_Hex_Semicolon_CR) {
  SetInput("<span foo=\"&#x0D;x\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\rx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_X_Hex_Semicolon_Control) {
  SetInput("<span foo=\"&#X81;x\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xC2\x81x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_x_Hex_Semicolon_Control2) {
  SetInput("<span foo=\"&#x82;x\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\x80\x9Ax", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_x_Hex_AnythingElse) {
  SetInput("<span foo=\"&#x2f1Ax\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\xBC\x9Ax", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_x_Hex_AnythingElse2) {
  SetInput("<span foo=\"&#x2f1A-\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\xBC\x9A-", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_x_AnythingElse) {
  SetInput("<span foo=\"&#xG\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&#xG", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_AnythingElse_Digit_Semicolon) {
  SetInput("<span foo=\"&#1234;x\">z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xD3\x92x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_AnythingElse_Digit_Semicolon_Control) {
  SetInput("<span foo=\"&#128;x\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\x82\xACx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_AnythingElse_Digit_AnythingElse) {
  SetInput("<span foo=\"&#1234a\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xD3\x92""a", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_NumberSign_AnythingElse_Digit_AnythingElse_Control) {
  SetInput("<span foo=\"&#128a\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\x82\xAC""a", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_Amp_AnythingElse) {
  SetInput("<span foo=\"&#x\">z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&#x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_NULL) {
  SetInput("<span foo=\"\x00\">z", sizeof("<span foo=\"\x00\">z")-1);
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xBF\xBD", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_EOF) {
  SetInput("<span foo=\"");
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_TAG);
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Quote_AnythingElse) {
  SetInput("<span foo=\"b@#$'\t\n\f =<>!\">z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("b@#$'\t\n\f =<>!", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_Alnum_Match_Semicolon) {
  SetInput("<span foo='&fjlig;x'>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\x66\x6Ax", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_Alnum_Match_Alpha) {
  SetInput("<span foo='&aacutex'>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&aacutex", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_Alnum_Match_Num) {
  SetInput("<span foo='&aacute0'>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&aacute0", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_Alnum_Match_EQ) {
  SetInput("<span foo='&aacute='>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&aacute=", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_Alnum_Match_Otherwise) {
  SetInput("<span foo='&aacute'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xC3\xA1", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_Alnum_Otherwise_Alnum_Semicolon) {
  SetInput("<span foo='&1f;x'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_UNKNOWN_NAMED_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&1f;x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_Alnum_Otherwise_Alnum_AnythingElse) {
  SetInput("<span foo='&1f.x'>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&1f.x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_X_Hex_Semicolon_Zero) {
  SetInput("<span foo='&#X00;x'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_NULL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xBF\xBDx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_X_Hex_Semicolon_TooLarge) {
  SetInput("<span foo='&#XABCdef123;x'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CHARACTER_REFERENCE_OUTSIDE_UNICODE_RANGE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xBF\xBDx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_X_Hex_Semicolon_Surrogate) {
  SetInput("<span foo='&#XDb74;x'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_SURROGATE_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xBF\xBDx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_x_Hex_Semicolon_Noncharacter) {
  SetInput("<span foo='&#xFdD8;x'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xB7\x98x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_x_Hex_Semicolon_Noncharacter2) {
  SetInput("<span foo='&#x7FFFE;x'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xF1\xBF\xBF\xBEx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_x_Hex_Semicolon_C0Control) {
  SetInput("<span foo='&#x3;x'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\x03x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_x_Hex_Semicolon_NL) {
  SetInput("<span foo='&#x0A;x'>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\nx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_x_Hex_Semicolon_FF) {
  SetInput("<span foo='&#x0C;x'>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\fx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_x_Hex_Semicolon_CR) {
  SetInput("<span foo='&#x0D;x'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\rx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_X_Hex_Semicolon_Control) {
  SetInput("<span foo='&#X81;x'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xC2\x81x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_x_Hex_Semicolon_Control2) {
  SetInput("<span foo='&#x82;x'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\x80\x9Ax", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_x_Hex_AnythingElse) {
  SetInput("<span foo='&#x2f1Ax'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\xBC\x9Ax", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_x_Hex_AnythingElse2) {
  SetInput("<span foo='&#x2f1A-'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\xBC\x9A-", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_x_AnythingElse) {
  SetInput("<span foo='&#xG'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&#xG", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_AnythingElse_Digit_Semicolon) {
  SetInput("<span foo='&#1234;x'>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xD3\x92x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_AnythingElse_Digit_Semicolon_Control) {
  SetInput("<span foo='&#128;x'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\x82\xACx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_AnythingElse_Digit_AnythingElse) {
  SetInput("<span foo='&#1234a'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xD3\x92""a", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_NumberSign_AnythingElse_Digit_AnythingElse_Control) {
  SetInput("<span foo='&#128a'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\x82\xAC""a", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_Amp_AnythingElse) {
  SetInput("<span foo='&#x'>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&#x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_NULL) {
  SetInput("<span foo='\x00'>z", sizeof("<span foo='\x00'>z")-1);
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xBF\xBD", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_EOF) {
  SetInput("<span foo='");
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_TAG);
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_Apos_AnythingElse) {
  SetInput("<span foo='b@#$\"\t\n\f =<>!'>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("b@#$\"\t\n\f =<>!", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_GT) {
  SetInput("<span foo=>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_ATTRIBUTE_VALUE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_Alnum_Match_Semicolon) {
  SetInput("<span foo=&fjlig;x>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\x66\x6Ax", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_Alnum_Match_Alpha) {
  SetInput("<span foo=&aacutex>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&aacutex", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_Alnum_Match_Num) {
  SetInput("<span foo=&aacute0>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&aacute0", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_Alnum_Match_Otherwise) {
  SetInput("<span foo=&aacute>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xC3\xA1", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_Alnum_Otherwise_Alnum_Semicolon) {
  SetInput("<span foo=&1f;x>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_UNKNOWN_NAMED_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&1f;x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_Alnum_Otherwise_Alnum_AnythingElse) {
  SetInput("<span foo=&1f.x>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&1f.x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_X_Hex_Semicolon_Zero) {
  SetInput("<span foo=&#X00;x>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_NULL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xBF\xBDx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_X_Hex_Semicolon_TooLarge) {
  SetInput("<span foo=&#XABCdef123;x>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CHARACTER_REFERENCE_OUTSIDE_UNICODE_RANGE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xBF\xBDx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_X_Hex_Semicolon_Surrogate) {
  SetInput("<span foo=&#XDb74;x>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_SURROGATE_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xBF\xBDx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_x_Hex_Semicolon_Noncharacter) {
  SetInput("<span foo=&#xFdD8;x>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xB7\x98x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_x_Hex_Semicolon_Noncharacter2) {
  SetInput("<span foo=&#x7FFFE;x>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xF1\xBF\xBF\xBEx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_x_Hex_Semicolon_C0Control) {
  SetInput("<span foo=&#x3;x>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\x03x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_x_Hex_Semicolon_NL) {
  SetInput("<span foo=&#x0A;x>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\nx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_x_Hex_Semicolon_FF) {
  SetInput("<span foo=&#x0C;x>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\fx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_x_Hex_Semicolon_CR) {
  SetInput("<span foo=&#x0D;x>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\rx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_X_Hex_Semicolon_Control) {
  SetInput("<span foo=&#X81;x>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xC2\x81x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_x_Hex_Semicolon_Control2) {
  SetInput("<span foo=&#x82;x>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\x80\x9Ax", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_x_Hex_AnythingElse) {
  SetInput("<span foo=&#x2f1Ax>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\xBC\x9Ax", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_x_Hex_AnythingElse2) {
  SetInput("<span foo=&#x2f1A->z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\xBC\x9A-", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_x_AnythingElse) {
  SetInput("<span foo=&#xG>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&#xG", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_AnythingElse_Digit_Semicolon) {
  SetInput("<span foo=&#1234;x>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xD3\x92x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_AnythingElse_Digit_Semicolon_Control) {
  SetInput("<span foo=&#128;x>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\x82\xACx", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_AnythingElse_Digit_AnythingElse) {
  SetInput("<span foo=&#1234a>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xD3\x92""a", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_NumberSign_AnythingElse_Digit_AnythingElse_Control) {
  SetInput("<span foo=&#128a>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE);
  Error(GUMBO_ERR_CONTROL_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xE2\x82\xAC""a", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_Amp_AnythingElse) {
  SetInput("<span foo=&#x>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("&#x", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_NULL) {
  SetInput("<span foo=\x00>z", sizeof("<span foo=\x00>z")-1);
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("\xEF\xBF\xBD", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_EOF) {
  SetInput("<span foo=");
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_TAG);
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_EQ_AnythingElse_AnythingElse) {
  SetInput("<span foo=b@#$!>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("b@#$!", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Alpha_Space_AnythingElse) {
  SetInput("<span foo bar=''>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(2, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("", attr->value);

  attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[1]);
  EXPECT_STREQ("bar", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_NULL) {
  SetInput("<span \x00=''>z", sizeof("<span \x00=''>z")-1);
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("\xEF\xBF\xBD", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Quote) {
  SetInput("<span \"=''>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_UNEXPECTED_CHARACTER_IN_ATTRIBUTE_NAME);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("\"", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_Apos) {
  SetInput("<span '=''>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_UNEXPECTED_CHARACTER_IN_ATTRIBUTE_NAME);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("'", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Space_AnythingElse_LT) {
  SetInput("<span <=''>z");
  NextStartTag(GUMBO_TAG_SPAN, true);
  Error(GUMBO_ERR_UNEXPECTED_CHARACTER_IN_ATTRIBUTE_NAME);
  ASSERT_EQ(1, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("<", attr->name);
  EXPECT_STREQ("", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_MultipleAttributes) {
  SetInput("<span foo=\"123\"\tbar='456'\nbaz=789\f>z");
  NextStartTag(GUMBO_TAG_SPAN);
  ASSERT_EQ(3, token_.v.start_tag.attributes.length);
  GumboAttribute *attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[0]);
  EXPECT_STREQ("foo", attr->name);
  EXPECT_STREQ("123", attr->value);

  attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[1]);
  EXPECT_STREQ("bar", attr->name);
  EXPECT_STREQ("456", attr->value);

  attr = static_cast<GumboAttribute*>(token_.v.start_tag.attributes.data[2]);
  EXPECT_STREQ("baz", attr->name);
  EXPECT_STREQ("789", attr->value);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Slash_GT) {
  SetInput("<br/>z");
  NextStartTag(GUMBO_TAG_BR);
  EXPECT_TRUE(token_.v.start_tag.is_self_closing);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Slash_EOF) {
  SetInput("<br/");
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_TAG);
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_Slash_AnythingElse) {
  SetInput("<br/ >z");
  NextStartTag(GUMBO_TAG_BR, true);
  Error(GUMBO_ERR_UNEXPECTED_SOLIDUS_IN_TAG);
  EXPECT_FALSE(token_.v.start_tag.is_self_closing);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_GT) {
  SetInput("<mATh>z");
  NextStartTag(GUMBO_TAG_MATH);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_NULL) {
  SetInput("<s\x00pan>z", sizeof("<s\x00pan>z")-1);
  Next(true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  ASSERT_EQ(GUMBO_TOKEN_START_TAG, token_.type);
  EXPECT_EQ(GUMBO_TAG_UNKNOWN, token_.v.start_tag.tag);
  EXPECT_STREQ("s\xEF\xBF\xBDpan", token_.v.start_tag.name);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_EOF) {
  SetInput("<sp");
  AtEnd(true);
  Error(GUMBO_ERR_EOF_IN_TAG);
}

TEST_F(GumboTokenizerTest, Data_LT_Alpha_AnythingElse) {
  SetInput("<h5?-&!]>z");
  Next();
  ASSERT_EQ(GUMBO_TOKEN_START_TAG, token_.type);
  EXPECT_EQ(GUMBO_TAG_UNKNOWN, token_.v.start_tag.tag);
  EXPECT_STREQ("h5?-&!]", token_.v.start_tag.name);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_Question) {
  SetInput("<?php ?>z");
  NextComment("?php ?", true);
  Error(GUMBO_ERR_UNEXPECTED_QUESTION_MARK_INSTEAD_OF_TAG_NAME);
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_LT_EOF) {
  SetInput("<");
  NextChar('<', true);
  Error(GUMBO_ERR_EOF_BEFORE_TAG_NAME);
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_LT_AnythingElse) {
  SetInput("<0z");
  NextChar('<', true);
  Error(GUMBO_ERR_INVALID_FIRST_CHARACTER_OF_TAG_NAME);
  NextChar('0');
  NextChar('z');
}

TEST_F(GumboTokenizerTest, Data_NULL) {
  SetInput("", 1);
  Next(true);
  Error(GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  ASSERT_EQ(GUMBO_TOKEN_NULL, token_.type);
  EXPECT_EQ(0, token_.v.character);
}

TEST_F(GumboTokenizerTest, Data_EOF) {
  SetInput("");
  AtEnd();
}

TEST_F(GumboTokenizerTest, Data_AnythingElse) {
  SetInput("a\xce\xb2\xd7\x92");
  NextChar(0x61);
  NextChar(0x03B2);
  NextChar(0x05D2);
}

TEST_F(GumboTokenizerTest, UTF8_BOM) {
  SetInput("\xEF\xBB\xBF<b>");
  Next();
  ASSERT_EQ(GUMBO_TOKEN_START_TAG, token_.type);
  EXPECT_EQ(GUMBO_TAG_B, token_.v.start_tag.tag);
  AtEnd();
}

}  // namespace
// vim: set sw=2 sts=2 ts=8 et:
