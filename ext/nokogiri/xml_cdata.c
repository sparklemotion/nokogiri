#include <xml_cdata.h>

/*
 * call-seq:
 *  new(document, content)
 *
 * Create a new CData element on the +document+ with +content+
 */
static VALUE new(int argc, VALUE *argv, VALUE klass)
{
  xmlDocPtr xml_doc;
  VALUE doc;
  VALUE content;
  VALUE rest;

  rb_scan_args(argc, argv, "2*", &doc, &content, &rest);

  Data_Get_Struct(doc, xmlDoc, xml_doc);

  xmlNodePtr node = xmlNewCDataBlock(
      xml_doc->doc,
      Qnil == content ? NULL : (const xmlChar *)StringValuePtr(content),
      Qnil == content ? 0 : RSTRING_LEN(content)
  );

  NOKOGIRI_ROOT_NODE(node);

  VALUE rb_node = Nokogiri_wrap_xml_node(klass, node);
  rb_funcall2(rb_node, rb_intern("initialize"), argc, argv);

  if(rb_block_given_p()) rb_yield(rb_node);

  return rb_node;
}

VALUE cNokogiriXmlCData;
void init_xml_cdata()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE node = rb_define_class_under(xml, "Node", rb_cObject);
  VALUE text = rb_define_class_under(xml, "Text", node);

  /*
   * CData represents a CData node in an xml document.
   */
  VALUE klass = rb_define_class_under(xml, "CDATA", text);


  cNokogiriXmlCData = klass;

  rb_define_singleton_method(klass, "new", new, -1);
}
