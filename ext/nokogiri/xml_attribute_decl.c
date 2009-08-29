#include <xml_attribute_decl.h>

/*
 * call-seq:
 *  attribute_type
 *
 * The attribute_type for this AttributeDecl
 */
static VALUE attribute_type(VALUE self)
{
  xmlAttributePtr node;
  Data_Get_Struct(self, xmlAttribute, node);
  return INT2NUM((int)node->atype);
}

VALUE cNokogiriXmlAttributeDecl;

void init_xml_attribute_decl()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE node = rb_define_class_under(xml, "Node", rb_cObject);
  VALUE klass = rb_define_class_under(xml, "AttributeDecl", node);

  cNokogiriXmlAttributeDecl = klass;

  rb_define_method(klass, "attribute_type", attribute_type, 0);
}
