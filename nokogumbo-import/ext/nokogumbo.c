#include <ruby.h>
#include <gumbo.h>
#include <nokogiri.h>
#include <libxml/tree.h>

// class constants
static VALUE Document;

static const char* const TAGS[] = {
  "html",
  "head",
  "title",
  "base",
  "link",
  "meta",
  "style",
  "script",
  "noscript",
  "body",
  "section",
  "nav",
  "article",
  "aside",
  "h1",
  "h2",
  "h3",
  "h4",
  "h5",
  "h6",
  "hgroup",
  "header",
  "footer",
  "address",
  "p",
  "hr",
  "pre",
  "blockquote",
  "ol",
  "ul",
  "li",
  "dl",
  "dt",
  "dd",
  "figure",
  "figcaption",
  "div",
  "a",
  "em",
  "strong",
  "small",
  "s",
  "cite",
  "q",
  "dfn",
  "abbr",
  "time",
  "code",
  "var",
  "samp",
  "kbd",
  "sub",
  "sup",
  "i",
  "b",
  "mark",
  "ruby",
  "rt",
  "rp",
  "bdi",
  "bdo",
  "span",
  "br",
  "wbr",
  "ins",
  "del",
  "image",
  "img",
  "iframe",
  "embed",
  "object",
  "param",
  "video",
  "audio",
  "source",
  "track",
  "canvas",
  "map",
  "area",
  "math",
  "mi",
  "mo",
  "mn",
  "ms",
  "mtext",
  "mglyph",
  "malignmark",
  "annotation_xml",
  "svg",
  "foreignobject",
  "desc",
  "table",
  "caption",
  "colgroup",
  "col",
  "tbody",
  "thead",
  "tfoot",
  "tr",
  "td",
  "th",
  "form",
  "fieldset",
  "legend",
  "label",
  "input",
  "button",
  "select",
  "datalist",
  "optgroup",
  "option",
  "textarea",
  "keygen",
  "output",
  "progress",
  "meter",
  "details",
  "summary",
  "command",
  "menu",
  "applet",
  "acronym",
  "bgsound",
  "dir",
  "frame",
  "frameset",
  "noframes",
  "isindex",
  "listing",
  "xmp",
  "nextid",
  "noembed",
  "plaintext",
  "rb",
  "strike",
  "basefont",
  "big",
  "blink",
  "center",
  "font",
  "marquee",
  "multicol",
  "nobr",
  "spacer",
  "tt",
  "u",
  "unknown"
};

const static int Unknown=sizeof(TAGS)/sizeof(char*)-1;

// determine tag name for a given node
static xmlNodePtr new_element(GumboElement *node) {
  xmlNodePtr element;
  if (node->tag != Unknown) {
    element = xmlNewNode(NULL, BAD_CAST TAGS[(int)node->tag]);
  } else {
    // Gumbo doesn't provide unknown tags, so we need to parse it ourselves:
    // http://www.w3.org/html/wg/drafts/html/CR/syntax.html#tag-name-state
    GumboStringPiece *tag = &node->original_tag;
    int length;
    for (length = 1; length < tag->length-1; length++) {
      if (strchr(" \t\r\n<", *((char*)tag->data+length))) break; 
    }
    char name[length];
    strncpy(name, 1+(char *)tag->data, length-1);
    name[length-1] = '\0';
    element = xmlNewNode(NULL, BAD_CAST name);
  }
  return element;
}

// Build a Nokogiri Element for a given GumboElement (recursively)
static xmlNodePtr walk_tree(xmlDocPtr document, GumboElement *node) {
  xmlNodePtr element = new_element(node);

  // add in the attributes
  GumboVector* attrs = &node->attributes;
  for (int i=0; i < attrs->length; i++) {
    GumboAttribute *attr = attrs->data[i];
    xmlNewProp(element, BAD_CAST attr->name, BAD_CAST attr->value);
  }

  // add in the children
  GumboVector* children = &node->children;
  for (int i=0; i < children->length; i++) {
    GumboNode* child = children->data[i];

    xmlNodePtr node = NULL;

    switch (child->type) {
      case GUMBO_NODE_ELEMENT:
        node = walk_tree(document, &child->v.element);
        break;
      case GUMBO_NODE_WHITESPACE:
      case GUMBO_NODE_TEXT:
        node = xmlNewText(BAD_CAST child->v.text.text);
        break;
      case GUMBO_NODE_CDATA:
        node = xmlNewCDataBlock(document, 
          BAD_CAST child->v.text.original_text.data,
          child->v.text.original_text.length);
        break;
      case GUMBO_NODE_COMMENT:
        node = xmlNewComment(BAD_CAST child->v.text.text);
        break;
      case GUMBO_NODE_DOCUMENT:
        break; // should never happen -- ignore
    }

    if (node) xmlAddChild(element, node);
  }

  return element;
}

// Parse a string using gumbo_parse into a Nokogiri document
static VALUE t_parse(VALUE self, VALUE string) {
  GumboOutput *output = gumbo_parse_with_options(
    &kGumboDefaultOptions, RSTRING_PTR(string), RSTRING_LEN(string)
  );
  xmlDocPtr doc = xmlNewDoc(BAD_CAST "1.0");
  xmlNodePtr root = walk_tree(doc, &output->root->v.element);
  xmlDocSetRootElement(doc, root);
  if (output->document->v.document.has_doctype) {
    const char *public = output->document->v.document.public_identifier;
    const char *system = output->document->v.document.system_identifier;
    xmlCreateIntSubset(doc, BAD_CAST "html",
      (strlen(public) ? public : NULL),
      (strlen(system) ? system : NULL));
  }
  gumbo_destroy_output(&kGumboDefaultOptions, output);

  return Nokogiri_wrap_xml_document(Document, doc);
}

// Initialize the Nokogumbo class and fetch constants we will use later
void Init_nokogumboc() {
  rb_funcall(rb_mKernel, rb_intern("gem"), 1, rb_str_new2("nokogiri"));
  rb_require("nokogiri");

  // class constants
  VALUE Nokogiri = rb_const_get(rb_cObject, rb_intern("Nokogiri"));
  VALUE HTML = rb_const_get(Nokogiri, rb_intern("HTML"));
  Document = rb_const_get(HTML, rb_intern("Document"));

  // define Nokogumbo class with a singleton parse method
  VALUE Gumbo = rb_define_class("Nokogumbo", rb_cObject);
  rb_define_singleton_method(Gumbo, "parse", t_parse, 1);
}

