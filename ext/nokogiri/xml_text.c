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
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");

  /*
   * Wraps Text nodes.
   */
  VALUE klass = rb_define_class_under(xml, "Text", cNokogiriXmlNode);

  cNokogiriXmlText = klass;

  rb_define_singleton_method(klass, "new", new, 2);
}
