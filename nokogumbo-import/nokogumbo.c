#include <ruby.h>
#include <gumbo.h>
#include <nokogiri.h>
#include <libxml/tree.h>

#define CONST_CAST (xmlChar const*)

// class constants
static VALUE Document;

// Build a Nokogiri Element for a given GumboElement (recursively)
static xmlNodePtr walk_tree(xmlDocPtr document, GumboElement *node) {
  // determine tag name for a given node
  xmlNodePtr element;
  if (node->tag != GUMBO_TAG_UNKNOWN) {
    element = xmlNewNode(NULL, CONST_CAST gumbo_normalized_tagname(node->tag));
  } else {
    GumboStringPiece tag = node->original_tag;
    gumbo_tag_from_original_text(&tag);
    char name[tag.length+1];
    strncpy(name, tag.data, tag.length);
    name[tag.length] = '\0';
    element = xmlNewNode(NULL, BAD_CAST name);
  }

  // add in the attributes
  GumboVector* attrs = &node->attributes;
  for (int i=0; i < attrs->length; i++) {
    GumboAttribute *attr = attrs->data[i];
    xmlNewProp(element, CONST_CAST attr->name, CONST_CAST attr->value);
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
        node = xmlNewText(CONST_CAST child->v.text.text);
        break;
      case GUMBO_NODE_CDATA:
        node = xmlNewCDataBlock(document, 
          CONST_CAST child->v.text.original_text.data,
          (int) child->v.text.original_text.length);
        break;
      case GUMBO_NODE_COMMENT:
        node = xmlNewComment(CONST_CAST child->v.text.text);
        break;
      case GUMBO_NODE_DOCUMENT:
        break; // should never happen -- ignore
    }

    if (node) xmlAddChild(element, node);
  }

  return element;
}

// Parse a string using gumbo_parse into a Nokogiri document
static VALUE parse(VALUE self, VALUE string) {
  GumboOutput *output = gumbo_parse_with_options(
    &kGumboDefaultOptions, RSTRING_PTR(string),
    (size_t) RSTRING_LEN(string)
  );
  xmlDocPtr doc = xmlNewDoc(CONST_CAST "1.0");
  xmlNodePtr root = walk_tree(doc, &output->root->v.element);
  xmlDocSetRootElement(doc, root);
  if (output->document->v.document.has_doctype) {
    const char *public = output->document->v.document.public_identifier;
    const char *system = output->document->v.document.system_identifier;
    xmlCreateIntSubset(doc, CONST_CAST "html",
      (strlen(public) ? CONST_CAST public : NULL),
      (strlen(system) ? CONST_CAST system : NULL));
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
  rb_define_singleton_method(Gumbo, "parse", parse, 1);
}
