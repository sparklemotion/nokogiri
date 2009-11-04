#include <xml_encoding_handler.h>

static VALUE get(VALUE self, VALUE key)
{
  xmlCharEncodingHandlerPtr handler;
  
  handler = xmlFindCharEncodingHandler(StringValuePtr(key));
  if(handler) return Qtrue;
  return Qnil;
}

void init_xml_encoding_handler()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE klass = rb_define_class_under(nokogiri, "EncodingHandler", rb_cObject);

  rb_define_singleton_method(klass, "[]", get, 1);
}
