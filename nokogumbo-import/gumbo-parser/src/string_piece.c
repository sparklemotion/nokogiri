// Copyright 2010 Google Inc.
// Licensed under the Apache License, version 2.0.

#include "string_piece.h"

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

#include "util.h"

struct GumboInternalParser;

const GumboStringPiece kGumboEmptyString = {NULL, 0};

bool gumbo_string_equals (
  const GumboStringPiece* str1,
  const GumboStringPiece* str2
) {
  return
    str1->length == str2->length
    && !memcmp(str1->data, str2->data, str1->length);
}

bool gumbo_string_equals_ignore_case (
  const GumboStringPiece* str1,
  const GumboStringPiece* str2
) {
  return
    str1->length == str2->length
    && !strncasecmp(str1->data, str2->data, str1->length);
}

void gumbo_string_copy (
  struct GumboInternalParser* parser,
  GumboStringPiece* dest,
  const GumboStringPiece* source
) {
  dest->length = source->length;
  char* buffer = gumbo_parser_allocate(parser, source->length);
  memcpy(buffer, source->data, source->length);
  dest->data = buffer;
}
