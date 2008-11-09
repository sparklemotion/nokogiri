#include <xml_text.h>

static VALUE new(VALUE klass, VALUE string, VALUE document)
{
  xmlDocPtr doc;
  Data_Get_Struct(document, xmlDoc, doc);

  xmlNodePtr node = xmlNewText((xmlChar *)StringValuePtr(string));
  node->doc = doc;

  VALUE rb_node = Nokogiri_wrap_xml_node(node) ;

  if(rb_block_given_p()) rb_yield(rb_node);

  return rb_node;
}

VALUE cNokogiriXmlText ;
void init_xml_text()
{
  VALUE klass = cNokogiriXmlText = rb_const_get(mNokogiriXml, rb_intern("Text"));

  rb_define_singleton_method(klass, "new", new, 2);
}
