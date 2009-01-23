#include <xml_processing_instruction.h>

/*
 * call-seq:
 *  new(document, name, content)
 *
 * Create a new ProcessingInstruction element on the +document+ with +name+
 * and +content+
 */
static VALUE new(VALUE klass, VALUE doc, VALUE name, VALUE content)
{
  xmlDocPtr xml_doc;
  Data_Get_Struct(doc, xmlDoc, xml_doc);

  xmlNodePtr node = xmlNewDocPI(
      xml_doc,
      (const xmlChar *)StringValuePtr(name),
      (const xmlChar *)StringValuePtr(content)
  );

  VALUE rb_node = Nokogiri_wrap_xml_node(node);

  if(rb_block_given_p()) rb_yield(rb_node);

  return rb_node;
}

VALUE cNokogiriXmlProcessingInstruction;
void init_xml_processing_instruction()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE node = rb_define_class_under(xml, "Node", rb_cObject);

  /*
   * ProcessingInstruction represents a ProcessingInstruction node in an xml
   * document.
   */
  VALUE klass = rb_define_class_under(xml, "ProcessingInstruction", node);

  cNokogiriXmlProcessingInstruction = klass;

  rb_define_singleton_method(klass, "new", new, 3);
}
