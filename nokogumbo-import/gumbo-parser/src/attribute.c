// Copyright 2010 Google Inc.
// Licensed under the Apache License, version 2.0.

#include "attribute.h"

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

#include "util.h"

struct GumboInternalParser;

GumboAttribute* gumbo_get_attribute (
  const GumboVector* attributes,
  const char* name
) {
  for (unsigned int i = 0; i < attributes->length; ++i) {
    GumboAttribute* attr = attributes->data[i];
    if (!strcasecmp(attr->name, name)) {
      return attr;
    }
  }
  return NULL;
}

void gumbo_destroy_attribute (
  struct GumboInternalParser* parser,
  GumboAttribute* attribute
) {
  gumbo_parser_deallocate(parser, (void*) attribute->name);
  gumbo_parser_deallocate(parser, (void*) attribute->value);
  gumbo_parser_deallocate(parser, (void*) attribute);
}
