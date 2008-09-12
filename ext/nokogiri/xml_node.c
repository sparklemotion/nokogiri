#include <xml_node.h>

VALUE Nokogiri_wrap_xml_node(xmlNodePtr root)
{
  VALUE klass = rb_eval_string("Nokogiri::XML::Node");
  VALUE node = Data_Wrap_Struct(klass, NULL, NULL, root);
  root->_private = (void *)node;
  return node;
}

static VALUE name(VALUE self)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);
  return rb_str_new2(node->name);
}

static VALUE document(VALUE self)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);

  if(!node->doc) return Qnil;
  return (VALUE)node->doc->_private;
}

static VALUE new(int argc, VALUE *argv, VALUE klass)
{
  VALUE name;
  VALUE ns;
  xmlNsPtr xml_ns = NULL;

  rb_scan_args(argc, argv, "11", &name, &ns);

  if (RTEST(ns))
    Data_Get_Struct(ns, xmlNs, xml_ns);

  xmlChar * xml_name = xmlCharStrdup(StringValuePtr(name));
  xmlNodePtr node = xmlNewNode(xml_ns, xml_name);
  free(xml_name);
  VALUE rb_node = Data_Wrap_Struct(klass, NULL, NULL, node);
  node->_private = rb_node;
  return rb_node;
}

void init_xml_node()
{
  VALUE m_nokogiri  = rb_const_get(rb_cObject, rb_intern("Nokogiri"));
  VALUE m_xml       = rb_const_get(m_nokogiri, rb_intern("XML"));
  VALUE klass       = rb_const_get(m_xml, rb_intern("Node"));

  rb_define_singleton_method(klass, "new", new, -1);
  rb_define_method(klass, "document", document, 0);
  rb_define_method(klass, "name", name, 0);
}
