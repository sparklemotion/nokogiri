#include <xml_comment.h>

/*
 * call-seq:
 *  new(document, content)
 *
 * Create a new Comment element on the +document+ with +content+
 */
static VALUE new(VALUE klass, VALUE doc, VALUE content)
{
  xmlDocPtr xml_doc;
  Data_Get_Struct(doc, xmlDoc, xml_doc);

  xmlNodePtr node = xmlNewDocComment(
      xml_doc,
      (const xmlChar *)StringValuePtr(content)
  );

  VALUE rb_node = Nokogiri_wrap_xml_node(node);

  if(rb_block_given_p()) rb_yield(rb_node);

  return rb_node;
}

VALUE cNokogiriXmlComment;
void init_xml_comment()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");

  /*
   * CData represents a CData node in an xml document.
   */
  VALUE klass = rb_define_class_under(xml, "Comment", cNokogiriXmlNode);


  cNokogiriXmlComment = klass;

  rb_define_singleton_method(klass, "new", new, 2);
}
