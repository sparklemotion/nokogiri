#include <xml_node.h>

VALUE Nokogiri_wrap_xml_node(xmlNodePtr root)
{
  VALUE klass = rb_eval_string("Nokogiri::XML::Node");
  return Data_Wrap_Struct(klass, NULL, NULL, root);
}

static VALUE new(int argc, VALUE *argv, VALUE klass)
{
  VALUE name;
  VALUE ns;
  xmlNsPtr xml_ns = NULL;

  rb_scan_args(argc, argv, "11", &name, &ns);

  if (ns)
    Data_Get_Struct(ns, xmlNs, xml_ns);

  xmlChar * xml_name = xmlCharStrdup(StringValuePtr(name));
  xmlNodePtr node = xmlNewNode(xml_ns, xml_name);
  free(xml_name);
  return Data_Wrap_Struct(klass, NULL, NULL, node);
}

void init_xml_node()
{
  VALUE m_nokogiri  = rb_const_get(rb_cObject, rb_intern("Nokogiri"));
  VALUE m_xml       = rb_const_get(m_nokogiri, rb_intern("XML"));
  VALUE klass       = rb_const_get(m_xml, rb_intern("Node"));

  rb_define_singleton_method(klass, "new", new, -1);
}
