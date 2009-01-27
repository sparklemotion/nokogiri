#include <xml_sax_push_parser.h>

static void deallocate(VALUE klass)
{
  printf("XML::SAX::PushParser dealloc\n");
}

static VALUE allocate(VALUE klass)
{
  return Data_Wrap_Struct(klass, NULL, deallocate, NULL);
}

static VALUE initialize_native(VALUE self, VALUE _xml_sax, VALUE _filename)
{
  xmlSAXHandlerPtr sax;

  Data_Get_Struct(_xml_sax, xmlSAXHandler, sax);
  
  const char * filename = NULL;

  if(_filename != Qnil) filename = StringValuePtr(_filename);

  xmlParserCtxtPtr ctx = xmlCreatePushParserCtxt(
      sax,
      NULL,
      NULL,
      0,
      filename
  );

  DATA_PTR(self) = ctx;
  return self;
}

VALUE cNokogiriXmlSaxPushParser ;
void init_xml_sax_push_parser()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE sax = rb_define_module_under(xml, "SAX");
  VALUE klass = rb_define_class_under(sax, "PushParser", rb_cObject);

  cNokogiriXmlSaxPushParser = klass;

  rb_define_alloc_func(klass, allocate);
  rb_define_private_method(klass, "initialize_native", initialize_native, 2);
}
