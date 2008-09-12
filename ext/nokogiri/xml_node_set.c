#include <xml_node_set.h>

/*
 * call-seq:
 *  length
 *
 * Get the length of the node set
 */
static VALUE length(VALUE self)
{
  xmlNodeSetPtr node_set;
  Data_Get_Struct(self, xmlNodeSet, node_set);

  return INT2NUM(node_set->nodeNr);
}

/*
 * call-seq:
 *  [](i)
 *
 * Get the node at index +i+
 */
static VALUE index_at(VALUE self, VALUE number)
{
  int i = NUM2INT(number);
  xmlNodeSetPtr node_set;
  Data_Get_Struct(self, xmlNodeSet, node_set);

  if(i >= node_set->nodeNr) return Qnil;
  VALUE klass = rb_eval_string("Nokogiri::XML::Node");

  return Data_Wrap_Struct(klass, NULL, NULL, node_set->nodeTab[i]);
}

void init_xml_node_set(void)
{
  VALUE klass = rb_eval_string("Nokogiri::XML::NodeSet");
  rb_define_method(klass, "length", length, 0);
  rb_define_method(klass, "[]", index_at, 1);
}
