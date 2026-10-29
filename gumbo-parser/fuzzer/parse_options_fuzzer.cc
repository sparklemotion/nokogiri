#include "../src/nokogiri_gumbo.h"
#include <limits.h>
#include <stdint.h>
#include <string.h>

/*
 *  Like parse_fuzzer, but the first HEADER_SIZE bytes of the input choose the GumboOptions that
 *  ext/nokogiri/gumbo.c can set, including fragment parsing. The rest of the input is the HTML.
 */
#define HEADER_SIZE 6

static const char* const kEncodings[] = {NULL, "text/html", "application/xhtml+xml"};

size_t sink;

static void WalkTree(const GumboNode* node) {
  switch (node->type) {
    case GUMBO_NODE_DOCUMENT:
      for (unsigned int i = 0; i < node->v.document.children.length; ++i) {
        WalkTree(static_cast<const GumboNode*>(node->v.document.children.data[i]));
      }
      break;
    case GUMBO_NODE_ELEMENT:
    case GUMBO_NODE_TEMPLATE: {
      const GumboElement* element = &node->v.element;
      sink += strlen(element->name);
      for (unsigned int i = 0; i < element->attributes.length; ++i) {
        const GumboAttribute* attribute = static_cast<const GumboAttribute*>(element->attributes.data[i]);
        sink += strlen(attribute->name) + strlen(attribute->value);
      }
      for (unsigned int i = 0; i < element->children.length; ++i) {
        WalkTree(static_cast<const GumboNode*>(element->children.data[i]));
      }
      break;
    }
    default:
      sink += strlen(node->v.text.text);
      break;
  }
}

static GumboOptions OptionsFromHeader(const uint8_t* header) {
  GumboOptions options = kGumboDefaultOptions;

  options.parse_noscript_content_as_text = header[0] & 0x01;
  options.max_tree_depth = header[1] == 0 ? UINT_MAX : header[1] - 1;
  options.max_attributes = header[2] - 1;
  options.max_errors = header[3] == 0 ? -1 : header[3] - 1;

  if (header[0] & 0x02) {
    GumboTag tag = static_cast<GumboTag>(header[4] % GUMBO_TAG_LAST);
    options.fragment_context = tag == GUMBO_TAG_UNKNOWN ? "x-custom" : gumbo_normalized_tagname(tag);
    options.fragment_namespace = static_cast<GumboNamespaceEnum>((header[0] >> 2) % 3);
    options.fragment_encoding = kEncodings[(header[0] >> 4) % 3];
    options.quirks_mode = static_cast<GumboQuirksModeEnum>((header[0] >> 6) % 3);
    options.fragment_context_has_form_ancestor = header[5] & 0x01;
    if (options.max_tree_depth < UINT_MAX) {
      options.max_tree_depth++;
    }
  }

  return options;
}

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  /* arbitrary upper size limit to avoid "out-of-memory in parse_fuzzer" reports */
  if (size < HEADER_SIZE || size > HEADER_SIZE + 25000) {
    return 0;
  }

  GumboOptions options = OptionsFromHeader(data);
  const char* html = reinterpret_cast<const char*>(data + HEADER_SIZE);
  size_t html_length = size - HEADER_SIZE;

  GumboOutput* output = gumbo_parse_with_options(&options, html, html_length);
  WalkTree(output->document);
  gumbo_destroy_output(output);

  return 0;
}
