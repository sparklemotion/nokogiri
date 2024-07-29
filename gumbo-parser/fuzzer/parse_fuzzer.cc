#include "../src/nokogiri_gumbo.h"
#include <stdint.h>

int SanityCheckPointers(const char* input, size_t input_length, const GumboNode* node, int depth) {
  if (node->type == GUMBO_NODE_DOCUMENT || depth > 400) {
    return -1;
  }
  if (node->type == GUMBO_NODE_ELEMENT) {
    const GumboElement* element = &node->v.element;
    const GumboVector* attributes = &element->attributes;

    for (unsigned int i = 0; i < attributes->length; ++i) {
      const GumboAttribute* attribute = static_cast<const GumboAttribute*>(attributes->data[i]);
      if (!attribute)
      {
        return -1;
      }
    }
    const GumboVector* children = &element->children;
    for (unsigned int i = 0; i < children->length; ++i) {
      const GumboNode* child = static_cast<const GumboNode*>(children->data[i]);
      if (!child)
      {
        return -1;
      }
      SanityCheckPointers(input, input_length, child, depth + 1);
    }
  } else {
    const GumboText* text = &node->v.text;
    if (!text)
    {
      return -1;
    }
  }

  return 0;
}

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  /* arbitrary upper size limit to avoid "out-of-memory in parse_fuzzer" reports */
  if (size < 10 | size > 25000) {
    return 0;
  }

  GumboOptions options = kGumboDefaultOptions;
  GumboOutput* output = gumbo_parse_with_options(&options, (char*)data, size);

  int result = SanityCheckPointers((char*)data, size, output->root, 0);

  if (output) {
    gumbo_destroy_output(output);
  }

  if (result < 0) {
    return -1;
  }

  return 0;
}
