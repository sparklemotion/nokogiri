#include <nokogiri.h>

VALUE cNokogiriXmlText ;

/*
 * call-seq:
 *  new(content, document)
 *
 * Create a new Text element on the +document+ with +content+
 */
static VALUE
new (int argc, VALUE *argv, VALUE klass)
{
  xmlDocPtr doc;
  xmlNodePtr node;
  VALUE string;
  VALUE document;
  VALUE rest;
  VALUE rb_node;

  rb_scan_args(argc, argv, "2*", &string, &document, &rest);

  if (rb_obj_is_kind_of(document, cNokogiriXmlDocument)) {
    doc = noko_xml_document_unwrap(document);
  } else {
    xmlNodePtr deprecated_node_type_arg;
    // TODO: deprecate allowing Node
    NOKO_WARN_DEPRECATION("Passing a Node as the second parameter to Text.new is deprecated. Please pass a Document instead. This will become an error in a future release of Nokogiri.");
    Noko_Node_Get_Struct(document, xmlNode, deprecated_node_type_arg);
    doc = deprecated_node_type_arg->doc;
  }

  node = xmlNewText((xmlChar *)StringValueCStr(string));
  node->doc = doc;

  noko_xml_document_pin_node(node);

  rb_node = noko_xml_node_wrap(klass, node) ;
  rb_obj_call_init(rb_node, argc, argv);

  if (rb_block_given_p()) { rb_yield(rb_node); }

  return rb_node;
}

void
noko_init_xml_text(void)
{
  assert(cNokogiriXmlCharacterData);
  /*
   * Wraps Text nodes.
   */
  cNokogiriXmlText = rb_define_class_under(mNokogiriXml, "Text", cNokogiriXmlCharacterData);

  rb_define_singleton_method(cNokogiriXmlText, "new", new, -1);
}
