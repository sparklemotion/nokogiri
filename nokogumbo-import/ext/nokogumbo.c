#include "ruby.h"
#include "gumbo.h"

// class constants
static VALUE Nokogiri;
static VALUE HTML;
static VALUE XML;
static VALUE Document;
static VALUE Element;
static VALUE Text;
static VALUE CDATA;
static VALUE Comment;
static VALUE TAGS=0;
static int Unknown=0;

// interned symbols
static VALUE new;
static VALUE set_attribute;
static VALUE add_child;

// determine tag name for a given node
static VALUE _name(GumboElement *node) {
  if (!TAGS) {
    // Deferred initialization of "Unknown" as the GumboParser class is
    // defined *after* the Nokogumbo class is.
    VALUE HTML5 = rb_const_get(Nokogiri, rb_intern("HTML5"));
    TAGS = rb_const_get(HTML5, rb_intern("TAGS"));
    Unknown = NUM2INT(rb_const_get(HTML5, rb_intern("Unknown")));
  }

  if (node->tag != Unknown) {
    return rb_ary_entry(TAGS, (long) node->tag);
  } else {
    // Gumbo doesn't provide unknown tags, so we need to parse it ourselves:
    // http://www.w3.org/html/wg/drafts/html/CR/syntax.html#tag-name-state
    GumboStringPiece *tag = &node->original_tag;
    int length;
    for (length = 1; length < tag->length-1; length++) {
      if (strchr(" \t\r\n<", *((char*)tag->data+length))) break; 
    }
    return rb_str_new(1+(char *)tag->data, length-1);
  }
}

// Build a Nokogiri Element for a given GumboElement (recursively)
static VALUE _element(VALUE document, GumboElement *node) {
  int i;
  VALUE element = rb_funcall(Element, new, 2, _name(node), document);

  // add in the attributes
  GumboVector* attrs = &node->attributes;
  for (i=0; i < attrs->length; i++) {
    GumboAttribute *attr = attrs->data[i];
    VALUE name = rb_str_new2(attr->name);
    rb_funcall(element, set_attribute, 2, name, rb_str_new2(attr->value));
  }

  // add in the children
  GumboVector* children = &node->children;
  for (i=0; i < children->length; i++) {
    GumboNode* child = children->data[i];

    VALUE node = 0;
    VALUE text;

    switch (child->type) {
      case GUMBO_NODE_ELEMENT:
        node = _element(document, &child->v.element);
        break;
      case GUMBO_NODE_WHITESPACE:
      case GUMBO_NODE_TEXT:
        text = rb_str_new2(child->v.text.text);
        node = rb_funcall(Text, new, 2, text, document);
        break;
      case GUMBO_NODE_CDATA:
        text = rb_str_new2(child->v.text.text);
        node = rb_funcall(CDATA, new, 2, text, document);
        break;
      case GUMBO_NODE_COMMENT:
        text = rb_str_new2(child->v.text.text);
        node = rb_funcall(Comment, new, 2, document, text);
        break;
      case GUMBO_NODE_DOCUMENT:
        break; // should never happen -- ignore
    }

    if (node) rb_funcall(element, add_child, 1, node);
  }

  return element;
}

// Parse a string using gumbo_parse into a Nokogiri document
static VALUE t_parse(VALUE self, VALUE string) {
  VALUE document = rb_funcall(Document, new, 0);

  GumboOutput *output = gumbo_parse_with_options(
    &kGumboDefaultOptions, RSTRING_PTR(string), RSTRING_LEN(string)
  );
  VALUE root = _element(document, (GumboElement*)&output->root->v.element);
  rb_funcall(document, add_child, 1, root);
  gumbo_destroy_output(&kGumboDefaultOptions, output);

  return document;
}

// Initialize the Nokogumbo class and fetch constants we will use later
void Init_nokogumboc() {
  rb_funcall(rb_mKernel, rb_intern("gem"), 1, rb_str_new2("nokogiri"));
  rb_require("nokogiri");

  // class constants
  Nokogiri = rb_const_get(rb_cObject, rb_intern("Nokogiri"));
  HTML = rb_const_get(Nokogiri, rb_intern("HTML"));
  XML = rb_const_get(Nokogiri, rb_intern("XML"));
  Document = rb_const_get(HTML, rb_intern("Document"));
  Element = rb_const_get(XML, rb_intern("Element"));
  Text = rb_const_get(XML, rb_intern("Text"));
  CDATA = rb_const_get(XML, rb_intern("CDATA"));
  Comment = rb_const_get(XML, rb_intern("Comment"));

  // interned symbols
  new = rb_intern("new");
  set_attribute = rb_intern("set_attribute");
  add_child = rb_intern("add_child");

  // define Nokogumbo class with a singleton parse method
  VALUE Gumbo = rb_define_class("Nokogumbo", rb_cObject);
  rb_define_singleton_method(Gumbo, "parse", t_parse, 1);
}

