#include <html_sax_parser.h>

/*
 * call-seq:
 *  native_parse_file(data, encoding)
 *
 * Parse +data+ with +encoding+
 */
static VALUE native_parse_file(VALUE self, VALUE data, VALUE encoding)
{
  xmlSAXHandlerPtr handler;
  htmlDocPtr hdoc ;
  Data_Get_Struct(self, xmlSAXHandler, handler);
  hdoc = htmlSAXParseFile( StringValuePtr(data),
                           (const char *)StringValuePtr(encoding),
                           (htmlSAXHandlerPtr)handler,
                           (void *)self );
  xmlFreeDoc(hdoc);
  return data;
}

/*
 * call-seq:
 *  native_parse_memory(data, encoding)
 *
 * Parse +data+ with +encoding+
 */
static VALUE native_parse_memory(VALUE self, VALUE data, VALUE encoding)
{
  xmlSAXHandlerPtr handler;
  htmlDocPtr hdoc ;
  Data_Get_Struct(self, xmlSAXHandler, handler);
  hdoc = htmlSAXParseDoc(  (xmlChar *)StringValuePtr(data),
                           (const char *)StringValuePtr(encoding),
                           (htmlSAXHandlerPtr)handler,
                           (void *)self );
  xmlFreeDoc(hdoc);
  return data;
}

VALUE cNokogiriHtmlSaxParser ;
void init_html_sax_parser()
{
  VALUE nokogiri  = rb_define_module("Nokogiri");
  VALUE html      = rb_define_module_under(nokogiri, "HTML");
  VALUE sax       = rb_define_module_under(html, "SAX");
  /*
   * Nokogiri::HTML::SAX::Parser is used for parsing HTML with SAX
   * callbacks.
   */
  VALUE klass     = rb_define_class_under(sax, "Parser", cNokogiriXmlSaxParser);

  cNokogiriHtmlSaxParser = klass;

  rb_define_private_method(klass, "native_parse_memory", native_parse_memory, 2);
  rb_define_private_method(klass, "native_parse_file", native_parse_file, 2);
}
