#include <html_sax_parser.h>

static VALUE native_parse_file(VALUE self, VALUE data, VALUE encoding)
{
  // TODO: isn't it more interesting to return the doc tree than the data we passed in?
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

static VALUE native_parse_memory(VALUE self, VALUE data, VALUE encoding)
{
  // TODO: isn't it more interesting to return the doc tree than the data we passed in?
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
  VALUE klass = cNokogiriHtmlSaxParser =
    rb_const_get(mNokogiriHtmlSax, rb_intern("Parser"));
  rb_define_private_method(klass, "native_parse_memory", native_parse_memory, 2);
  rb_define_private_method(klass, "native_parse_file", native_parse_file, 2);
}
