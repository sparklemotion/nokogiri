#include <html_document.h>

static void dealloc(xmlDocPtr doc)
{
  xmlFreeDoc(doc);
}

static VALUE read_memory( VALUE klass,
                          VALUE string,
                          VALUE url,
                          VALUE encoding,
                          VALUE options )
{
  const char * c_buffer = StringValuePtr(string);
  const char * c_url    = (url == Qnil) ? NULL : StringValuePtr(url);
  const char * c_enc    = (encoding == Qnil) ? NULL : StringValuePtr(encoding);
  int len               = RSTRING(string)->len ;

  htmlDocPtr doc = htmlReadMemory(c_buffer, len, c_url, c_enc, NUM2INT(options));
  return Data_Wrap_Struct(klass, NULL, dealloc, doc);
}

static VALUE type(VALUE self)
{
  htmlDocPtr doc;
  Data_Get_Struct(self, xmlDoc, doc);
  return INT2NUM(doc->type);
}

void init_html_document()
{
  VALUE m_nokogiri  = rb_const_get(rb_cObject, rb_intern("Nokogiri"));
  VALUE m_xml       = rb_const_get(m_nokogiri, rb_intern("HTML"));
  VALUE klass       = rb_const_get(m_xml, rb_intern("Document"));

  rb_define_singleton_method(klass, "read_memory", read_memory, 4);
  rb_define_method(klass, "type", type, 0);
}
