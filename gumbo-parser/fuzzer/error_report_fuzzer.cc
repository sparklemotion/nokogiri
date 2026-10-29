// Fuzz the public parse-error reporting path that Nokogiri's HTML5 binding
// always runs after a parse (ext/nokogiri/gumbo.c, add_errors):
//   gumbo_parse_with_options()
//   gumbo_error_position() / gumbo_error_code()
//   gumbo_caret_diagnostic_to_string()
// The shipping parse_fuzzer calls gumbo_parse_with_options() with
// kGumboDefaultOptions and never reads output->errors, which is why error.c
// stays dark (17/503 lines, 3/17 functions in the 2024-04-25 production report,
// the latest_report_info date; coverage builds have been failing since).
//
// Threat model:
//   * Untrusted input: HTML bytes a Nokogiri user is asked to parse (file,
//     HTTP body, pasted markup) plus the fragment-context tag the caller
//     supplies.
//   * Trust boundary: gumbo_parse_with_options(), then the public error-string
//     APIs the binding calls on every recorded error.
//   * Attacker-adjacent options, enumerated the way the Ruby binding sets
//     them: fragment context/namespace/encoding, quirks mode, form ancestor,
//     noscript-as-text, tab stop, max_errors, max_attributes, max_tree_depth.
//     Never raw out-of-range enums.
//   * A real bug is an ASan/UBSan finding on those paths. A crash that needs
//     a violated contract (NULL error, source buffer shorter than the parse)
//     is a harness bug.
//
// Deliberately does not walk the open-element stack. A previous attempt that
// did (nokogiri-error-fragment-fuzzer, rejected 2026-10-28) hit a product
// null-deref in pop_current_node -> node_qualified_tagname_is on a parser-built
// end-tag token whose name was NULL (parser.c asserts element->name and
// tag != UNKNOWN || name; neither holds). That crash is recorded as finding
// nokogiri-1. This harness stops at the error list, which is the dark code,
// and keeps max_tree_depth at the production default so it does not keep
// re-entering that sink.

#include "../src/nokogiri_gumbo.h"

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

namespace {

const char* const kContexts[] = {
    "div",       "template", "table",     "tbody",    "tr",
    "td",        "select",   "title",     "textarea", "style",
    "script",    "xmp",      "iframe",    "noembed",  "noframes",
    "noscript",  "plaintext","svg",       "math",     "foreignObject",
    "annotation-xml", "head", "body",     "form",     "colgroup",
    "caption",   "option",   "ruby",      "frameset", "html",
    "mi",        "mo",       "mn",        "ms",       "mglyph",
    "malignmark","not-a-tag","DIV",
};

const char* const kEncodings[] = {
    "UTF-8", "utf-8", "ISO-8859-1", "windows-1252", "",
};

const char* const kQuirksNames[] = {"html", "HTML", "not-html", ""};
const char* const kQuirksPubids[] = {
    "-//ietf//dtd html 2.0//",
    "-//W3C//DTD HTML 4.0 Transitional//EN",
    "-//W3C//DTD HTML 4.01 Frameset//",
    "-//W3O//DTD W3 HTML Strict 3.0//EN//",
    "-/W3C/DTD HTML 4.0 Transitional/EN",
    "HTML",
    "+//silmaril//dtd html pro v0r11 19970101//",
    "-//unknown//dtd made up//",
    "",
};
const char* const kQuirksSysids[] = {
    "http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd",
    "about:legacy-compat",
    "",
};

struct InputView {
  const uint8_t* data;
  size_t size;
  size_t off;
};

uint8_t TakeByte(InputView* in) {
  if (in->off >= in->size) return 0;
  return in->data[in->off++];
}

// Format the errors the way ext/nokogiri/gumbo.c add_errors() does, then free
// the library-allocated message. Caps the walk so max_errors=-1 cannot turn
// one exec into an unbounded string-building loop; the parser still recorded
// every error.
void FormatErrors(const GumboOutput* output, const char* html, size_t html_len) {
  unsigned limit = output->errors.length;
  if (limit > 16) limit = 16;
  for (unsigned i = 0; i < limit; ++i) {
    const GumboError* err = static_cast<const GumboError*>(output->errors.data[i]);
    if (!err) continue;

    const char* code = gumbo_error_code(err);
    if (code) {
      volatile size_t n = strlen(code);
      (void)n;
    }
    GumboSourcePosition pos = gumbo_error_position(err);
    volatile unsigned line = static_cast<unsigned>(pos.line);
    (void)line;

    char* msg = nullptr;
    size_t msg_len = gumbo_error_to_string(err, &msg);
    if (msg) {
      volatile size_t sink = msg_len;
      (void)sink;
      free(msg);
    }

    char* caret = nullptr;
    size_t caret_len =
        gumbo_caret_diagnostic_to_string(err, html, html_len, &caret);
    if (caret) {
      volatile size_t sink = caret_len;
      (void)sink;
      free(caret);
    }
  }
}

}  // namespace

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  // Same ceiling the shipping parse_fuzzer uses, so a long input cannot
  // produce an "out-of-memory in fuzzer" report. The floor is lower because
  // error tokens are often a few bytes.
  if (size == 0 || size > 8192) return 0;

  InputView in = {data, size, 0};
  uint8_t flags = TakeByte(&in);

  GumboOptions options = kGumboDefaultOptions;
  // stop_on_first_error is a documented public option, but combined with
  // a fragment context it reaches a product assert in pop_current_node
  // (parser.c:603, tag != UNKNOWN || name) on parser-built end-tag tokens.
  // Finding nokogiri-1. Held at the production default (false) so this
  // target can keep exercising error.c; the reproducer is in findings/.
  options.stop_on_first_error = false;
  options.fragment_context_has_form_ancestor = (flags & 0x02) != 0;
  options.parse_noscript_content_as_text = (flags & 0x04) != 0;
  const bool use_fragment = (flags & 0x08) != 0;
  const bool call_quirks = (flags & 0x10) != 0;
  const bool custom_tab = (flags & 0x20) != 0;

  uint8_t ns_byte = TakeByte(&in);
  options.fragment_namespace = static_cast<GumboNamespaceEnum>(ns_byte % 3);

  uint8_t quirks_byte = TakeByte(&in);
  options.quirks_mode = static_cast<GumboQuirksModeEnum>(quirks_byte % 3);

  uint8_t limit_byte = TakeByte(&in);
  // Values the Ruby binding forwards, including 0 and unlimited (-1).
  static const int kMaxErrors[] = {-1, 0, 1, 4, 16};
  options.max_errors = kMaxErrors[limit_byte % 5];
  static const int kMaxAttributes[] = {1, 8, 400};
  options.max_attributes = kMaxAttributes[(limit_byte >> 3) % 3];
  // Keep the production tree-depth default (400). Depth 0/1 is what drove
  // the rejected pair into the pop_current_node null-deref (finding
  // nokogiri-1); it is not required to reach error.c.

  if (custom_tab) {
    uint8_t tab = TakeByte(&in);
    // tab_stop is a column divisor. 0 would divide by zero; default is 8.
    options.tab_stop = tab == 0 ? 8 : static_cast<int>(tab);
  }

  if (use_fragment) {
    options.fragment_context =
        kContexts[TakeByte(&in) % (sizeof(kContexts) / sizeof(kContexts[0]))];
    if ((TakeByte(&in) & 1) != 0) {
      options.fragment_encoding =
          kEncodings[TakeByte(&in) % (sizeof(kEncodings) / sizeof(kEncodings[0]))];
    }
  }

  if (in.off >= in.size) return 0;
  const char* html = reinterpret_cast<const char*>(data + in.off);
  size_t html_len = size - in.off;

  if (call_quirks) {
    const char* name = kQuirksNames[quirks_byte % 4];
    const char* pubid =
        kQuirksPubids[(quirks_byte + ns_byte) %
                      (sizeof(kQuirksPubids) / sizeof(kQuirksPubids[0]))];
    const char* sysid =
        kQuirksSysids[limit_byte % (sizeof(kQuirksSysids) / sizeof(kQuirksSysids[0]))];
    // NULL is the documented missing value.
    if ((flags & 0x40) != 0) name = nullptr;
    if ((flags & 0x80) != 0) pubid = nullptr;
    volatile int mode = gumbo_compute_quirks_mode(name, pubid, sysid);
    (void)mode;
  }

  GumboOutput* output = gumbo_parse_with_options(&options, html, html_len);
  if (!output) return 0;
  FormatErrors(output, html, html_len);
  if (output->status != GUMBO_STATUS_OK) {
    const char* status = gumbo_status_to_string(output->status);
    if (status) {
      volatile size_t n = strlen(status);
      (void)n;
    }
  }
  gumbo_destroy_output(output);
  return 0;
}
