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

#include "tokenizer.h"

#include <stdio.h>

#include "gtest/gtest.h"
#include "test_utils.h"

extern const char* kGumboTagNames[];

namespace {

// Tests for tokenizer.c
class GumboTokenizerTest : public GumboTest {
 protected:
  GumboTokenizerTest() : at_start_(true) {
    gumbo_tokenizer_state_init(&parser_, "", 0);
  }

  virtual ~GumboTokenizerTest() {
    gumbo_tokenizer_state_destroy(&parser_);
    gumbo_token_destroy(&token_);
  }

  void SetInput(const char* input) {
    if (!at_start_)
      gumbo_token_destroy(&token_);
    text_ = input;
    gumbo_tokenizer_state_destroy(&parser_);
    gumbo_tokenizer_state_init(&parser_, input, strlen(input));
    at_start_ = true;
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
    if (errors_are_expected) {
      errors_are_expected_ = true;
      EXPECT_FALSE(gumbo_lex(&parser_, &token_));
    } else {
      EXPECT_TRUE(gumbo_lex(&parser_, &token_));
    }
  }

  void NextChar(int c, bool errors_are_expected = false) {
    Next(errors_are_expected);
    ASSERT_EQ(GUMBO_TOKEN_CHARACTER, token_.type);
    EXPECT_EQ(c, token_.v.character);
  }

  void NextSpace(bool errors_are_expected = false) {
    Next(errors_are_expected);
    ASSERT_EQ(GUMBO_TOKEN_WHITESPACE, token_.type);
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

  void AtEnd(bool errors_are_expected = false) {
    Next(errors_are_expected);
    ASSERT_EQ(GUMBO_TOKEN_EOF, token_.type);
    EXPECT_EQ(-1, token_.v.character);
  }

  bool at_start_;
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

TEST_F(GumboTokenizerTest, PartialTag) {
  SetInput("<a");
  AtEnd(true);
}

TEST_F(GumboTokenizerTest, PartialTagWithAttributes) {
  SetInput("<a href=foo /");
  AtEnd(true);
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

TEST_F(GumboTokenizerTest, LexCharRef) {
  SetInput("&nbsp; Text");
  NextChar(0xa0);
  EXPECT_EQ(1, token_.position.column);
  EXPECT_EQ(1, token_.position.line);
  EXPECT_EQ(0, token_.position.offset);
  EXPECT_EQ('&', *token_.original_text.data);
  EXPECT_EQ(6, token_.original_text.length);

  NextSpace();
  EXPECT_EQ(' ', *token_.original_text.data);
  EXPECT_EQ(' ', token_.v.character);

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

TEST_F(GumboTokenizerTest, DoctypeUnterminated) {
  SetInput("<!DOCTYPE a PUBLIC''");
  Next(true);
  ASSERT_EQ(GUMBO_TOKEN_DOCTYPE, token_.type);
  EXPECT_EQ(0, token_.position.offset);

  GumboTokenDocType* doc_type = &token_.v.doc_type;
  EXPECT_TRUE(doc_type->force_quirks);
  EXPECT_TRUE(doc_type->has_public_identifier);
  EXPECT_FALSE(doc_type->has_system_identifier);
  EXPECT_STREQ("a", doc_type->name);
  EXPECT_STREQ("", doc_type->system_identifier);
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
  NextSpace();
  EXPECT_EQ(' ', token_.v.character);
  NextChar('<');
  NextSpace();
  NextChar('7');
  Advance(4);
  NextChar('<');
  NextChar('/');
  NextChar('d');
  Advance(27);
  NextChar('-');
  NextChar('-');
  NextChar('>');
  NextSpace();
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

TEST_F(GumboTokenizerTest, CData) {
  // SetInput uses strlen and so can't handle nulls.
  text_ = "<![CDATA[\0filler\0text\0]]>";
  gumbo_tokenizer_state_destroy(&parser_);
  gumbo_tokenizer_state_init(
      &parser_, text_, sizeof("<![CDATA[\0filler\0text\0]]>") - 1);
  gumbo_tokenizer_set_is_current_node_foreign(&parser_, true);

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
  NextEndTag(GUMBO_TAG_P);
  EXPECT_EQ(0, token_.position.offset);
  EXPECT_EQ("</p />", ToString(token_.original_text));

  GumboTokenEndTag* end_tag = &token_.v.end_tag;
  EXPECT_TRUE(end_tag->is_self_closing);
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
  Next(true);
  ASSERT_EQ(GUMBO_TOKEN_COMMENT, token_.type);
  EXPECT_STREQ("?xml is bogus-comment", token_.v.text);
  NextChar('T');
  NextChar('e');
  NextChar('x');
  NextChar('t');
  AtEnd();
}

TEST_F(GumboTokenizerTest, BogusComment2) {
  SetInput("</#bogus-comment");
  Next(true);
  ASSERT_EQ(GUMBO_TOKEN_COMMENT, token_.type);
  EXPECT_STREQ("#bogus-comment", token_.v.text);
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
  // because end tags don't take attributes), with the tokenizer passing through
  // the self-closing tag state in the process.
  SetInput("</div</th>");
  NextEndTag(GUMBO_TAG_UNKNOWN, true);
  EXPECT_STREQ("div<", token_.v.end_tag.name);
  EXPECT_EQ(0, token_.position.offset);
  EXPECT_EQ("</div</th>", ToString(token_.original_text));
}

TEST_F(GumboTokenizerTest, NullInTagNameState) {
  char input[] = { '<', 'x', 0, 'x', '>' };
  text_ = input;
  gumbo_tokenizer_state_destroy(&parser_);
  gumbo_tokenizer_state_init(&parser_, input, sizeof input);
  NextStartTag(GUMBO_TAG_UNKNOWN, true);
  EXPECT_EQ(0, token_.position.offset);
  EXPECT_STREQ("x\xEF\xBF\xBDx", token_.v.start_tag.name);
  AtEnd();
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
  NextChar('g');
  NextChar('o');
  NextChar('o');
  NextChar('g');
  NextChar('l');
  NextChar('e');
  AtEnd();
}

TEST_F(GumboTokenizerTest, NumericReplacement) {
  // Low quotation mark character.
  SetInput("&#X82");
  NextChar(0x201A, true);
  AtEnd();
}

TEST_F(GumboTokenizerTest, NumericInvalid) {
  SetInput("&#xDA00");
  NextChar(0xFFFD, true);
  AtEnd();
}

TEST_F(GumboTokenizerTest, NumericUtfInvalid) {
  SetInput("&#x007");
  NextChar(0x07, true);
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
  AtEnd();
}

}  // namespace
