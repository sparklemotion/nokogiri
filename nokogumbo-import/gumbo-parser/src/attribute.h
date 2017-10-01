// Copyright 2010 Google Inc.
// Licensed under the Apache License, version 2.0.

#ifndef GUMBO_ATTRIBUTE_H_
#define GUMBO_ATTRIBUTE_H_

#include "gumbo.h"

struct GumboInternalParser;

// Release the memory used for a GumboAttribute, including the attribute itself
void gumbo_destroy_attribute (
  struct GumboInternalParser* parser,
  GumboAttribute* attribute
);

#endif // GUMBO_ATTRIBUTE_H_
