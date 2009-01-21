#include <xml_entity_reference.h>

/*
 * call-seq:
 *  new(document, content)
 *
 * Create a new EntityReference element on the +document+ with +name+
 */
static VALUE new(VALUE klass, VALUE doc, VALUE name)
{
  xmlDocPtr xml_doc;
  Data_Get_Struct(doc, xmlDoc, xml_doc);

  xmlNodePtr node = xmlNewReference(
      xml_doc,
      (const xmlChar *)StringValuePtr(name)
  );

  VALUE rb_node = Nokogiri_wrap_xml_node(node);

  if(rb_block_given_p()) rb_yield(rb_node);

  return rb_node;
}

VALUE cNokogiriXmlEntityReference;
void init_xml_entity_reference()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE node = rb_define_class_under(xml, "Node", rb_cObject);

  /*
   * EntityReference represents an EntityReference node in an xml document.
   */
  VALUE klass = rb_define_class_under(xml, "EntityReference", node);

  cNokogiriXmlEntityReference = klass;

  rb_define_singleton_method(klass, "new", new, 2);
}
