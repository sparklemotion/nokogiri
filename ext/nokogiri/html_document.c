#include <html_document.h>

static void dealloc(xmlDocPtr doc)
{
  xmlFreeDoc(doc);
}

/*
 * call-seq:
 *  serialize
 *
 * Serialize this document
 */
static VALUE serialize(VALUE self)
{
  xmlDocPtr doc;
  xmlChar *buf;
  int size;
  Data_Get_Struct(self, xmlDoc, doc);

  htmlDocDumpMemory(doc, &buf, &size);
  VALUE rb_str = rb_str_new((char *)buf, (long)size);
  free(buf);
  return rb_str;
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

  if(doc == NULL)
    doc = htmlNewDoc((const xmlChar *)c_url, NULL);

  VALUE rb_doc = Data_Wrap_Struct(klass, NULL, dealloc, doc);
  doc->_private = (void*)rb_doc;
  return rb_doc;
}

static VALUE type(VALUE self)
{
  htmlDocPtr doc;
  Data_Get_Struct(self, xmlDoc, doc);
  return INT2NUM((int)doc->type);
}

VALUE cNokogiriHtmlDocument ;
void init_html_document()
{
  VALUE klass ;
  klass = cNokogiriHtmlDocument = rb_const_get(mNokogiriHtml, rb_intern("Document"));

  rb_define_singleton_method(klass, "read_memory", read_memory, 4);

  rb_define_method(klass, "type", type, 0);
  rb_define_method(klass, "serialize", serialize, 0);
}
