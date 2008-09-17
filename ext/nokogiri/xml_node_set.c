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
 *  push(node)
 *
 * Append +node+ to the NodeSet.
 */
static VALUE push(VALUE self, VALUE rb_node)
{
  xmlNodeSetPtr node_set;
  xmlNodePtr node;

  Data_Get_Struct(self, xmlNodeSet, node_set);
  Data_Get_Struct(rb_node, xmlNode, node);
  xmlXPathNodeSetAdd(node_set, node);
  return self;
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

static void deallocate(xmlNodeSetPtr node_set)
{
  xmlXPathFreeNodeSet(node_set);
}

static VALUE allocate(VALUE klass)
{
  xmlNodeSetPtr node_set = xmlXPathNodeSetCreate(NULL);
  return Data_Wrap_Struct(klass, NULL, deallocate, node_set);
}

VALUE cNokogiriXmlNodeSet ;
void init_xml_node_set(void)
{
  VALUE klass = cNokogiriXmlNodeSet = rb_eval_string("Nokogiri::XML::NodeSet");
  rb_define_alloc_func(klass, allocate);
  rb_define_method(klass, "length", length, 0);
  rb_define_method(klass, "[]", index_at, 1);
  rb_define_method(klass, "push", push, 1);
}
