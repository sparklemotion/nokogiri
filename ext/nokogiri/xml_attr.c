#include <xml_attr.h>

/*
 * call-seq:
 *  new(document, content)
 *
 * Create a new Attr element on the +document+ with +name+
 */
static VALUE new(VALUE klass, VALUE doc, VALUE name)
{
  xmlDocPtr xml_doc;
  Data_Get_Struct(doc, xmlDoc, xml_doc);

  xmlAttrPtr node = xmlNewDocProp(
      xml_doc,
      (const xmlChar *)StringValuePtr(name),
      NULL
  );

  VALUE rb_node = Nokogiri_wrap_xml_node((xmlNodePtr)node);

  if(rb_block_given_p()) rb_yield(rb_node);

  return rb_node;
}

VALUE cNokogiriXmlAttr;
void init_xml_attr()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE node = rb_define_class_under(xml, "Node", rb_cObject);

  /*
   * Attr represents a Attr node in an xml document.
   */
  VALUE klass = rb_define_class_under(xml, "Attr", node);


  cNokogiriXmlAttr = klass;

  rb_define_singleton_method(klass, "new", new, 2);
}
