#include <xml_text.h>

static void dealloc(xmlNodePtr node)
{
  if (! Nokogiri_xml_node_owned_get(node)) {
    NOKOGIRI_DEBUG_START_TEXT(node);
    xmlFreeNode(node);
    NOKOGIRI_DEBUG_END(node);
  }
}

static VALUE new(VALUE klass, VALUE string)
{
  xmlNodePtr node = xmlNewText((xmlChar *)StringValuePtr(string));
  VALUE rb_node = Data_Wrap_Struct(klass, NULL, dealloc, node);
  node->_private = (void *)rb_node;

  if(rb_block_given_p()) rb_yield(rb_node);

  return rb_node;
}

VALUE cNokogiriXmlText ;
void init_xml_text()
{
  VALUE klass = cNokogiriXmlText = rb_const_get(mNokogiriXml, rb_intern("Text"));

  rb_define_singleton_method(klass, "new", new, 1);
}
