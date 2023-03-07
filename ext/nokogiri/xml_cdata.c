#include <nokogiri.h>

VALUE cNokogiriXmlCData;

/*
 * call-seq:
 *  new(document, content)
 *
 * Create a new CDATA element on the +document+ with +content+
 *
 * If +content+ cannot be implicitly converted to a string, this method will
 * raise a TypeError exception.
 */
static VALUE
new (int argc, VALUE *argv, VALUE klass)
{
  xmlDocPtr xml_doc;
  xmlNodePtr node;
  VALUE doc;
  VALUE content;
  VALUE rest;
  VALUE rb_node;
  xmlChar *content_str = NULL;
  int content_str_len = 0;

  rb_scan_args(argc, argv, "2*", &doc, &content, &rest);

  if (rb_obj_is_kind_of(doc, cNokogiriXmlDocument)) {
    xml_doc = noko_xml_document_unwrap(doc);
  } else {
    xmlNodePtr deprecated_node_type_arg;
    // TODO: deprecate allowing Node
    NOKO_WARN_DEPRECATION("Passing a Node as the first parameter to CDATA.new is deprecated. Please pass a Document instead. This will become an error in a future release of Nokogiri.");
    Noko_Node_Get_Struct(doc, xmlNode, deprecated_node_type_arg);
    xml_doc = deprecated_node_type_arg->doc;
  }

  if (!NIL_P(content)) {
    content_str = (xmlChar *)StringValuePtr(content);
    content_str_len = RSTRING_LENINT(content);
  }

  node = xmlNewCDataBlock(xml_doc, content_str, content_str_len);

  noko_xml_document_pin_node(node);

  rb_node = noko_xml_node_wrap(klass, node);
  rb_obj_call_init(rb_node, argc, argv);

  if (rb_block_given_p()) { rb_yield(rb_node); }

  return rb_node;
}

void
noko_init_xml_cdata(void)
{
  assert(cNokogiriXmlText);
  /*
   * CData represents a CData node in an xml document.
   */
  cNokogiriXmlCData = rb_define_class_under(mNokogiriXml, "CDATA", cNokogiriXmlText);

  rb_define_singleton_method(cNokogiriXmlCData, "new", new, -1);
}
