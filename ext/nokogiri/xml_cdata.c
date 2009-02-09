#include <xml_cdata.h>

/*
 * call-seq:
 *  new(document, content)
 *
 * Create a new CData element on the +document+ with +content+
 */
static VALUE new(VALUE klass, VALUE doc, VALUE content)
{
  xmlDocPtr xml_doc;
  Data_Get_Struct(doc, xmlDoc, xml_doc);

  xmlNodePtr node = xmlNewCDataBlock(
      xml_doc,
      (const xmlChar *)StringValuePtr(content),
      RSTRING_LEN(content)
  );

  VALUE rb_node = Nokogiri_wrap_xml_node(node);

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

  rb_define_singleton_method(klass, "new", new, 2);
}
