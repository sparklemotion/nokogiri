#include <xml_node.h>

VALUE Nokogiri_wrap_xml_node(xmlNodePtr root)
{
  VALUE klass = rb_eval_string("Nokogiri::XML::Node");
  return Data_Wrap_Struct(klass, NULL, NULL, root);
}

void init_xml_node()
{
  VALUE m_nokogiri  = rb_const_get(rb_cObject, rb_intern("Nokogiri"));
  VALUE m_xml       = rb_const_get(m_nokogiri, rb_intern("XML"));
  VALUE klass       = rb_const_get(m_xml, rb_intern("Node"));
}
