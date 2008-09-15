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

  if(node_set)
    return INT2NUM(node_set->nodeNr);

  return INT2NUM(0);
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

  if(i >= node_set->nodeNr || abs(i) > node_set->nodeNr)
    return Qnil;

  if(i < 0)
    i = i + node_set->nodeNr;

  xmlNodePtr node = node_set->nodeTab[i];
  if(node->_private)
    return (VALUE)node->_private;

  VALUE rb_node = Data_Wrap_Struct(cNokogiriXmlNode, NULL, NULL, node_set->nodeTab[i]);
  node->_private = (void *)rb_node;
  rb_funcall(rb_node, rb_intern("decorate!"), 0);
  return rb_node;
}

VALUE cNokogiriXmlNodeSet ;
void init_xml_node_set(void)
{
  VALUE klass = cNokogiriXmlNodeSet = rb_eval_string("Nokogiri::XML::NodeSet");
  rb_define_method(klass, "length", length, 0);
  rb_define_method(klass, "[]", index_at, 1);
}
