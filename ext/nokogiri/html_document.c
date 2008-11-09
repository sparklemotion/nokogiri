#include <html_document.h>

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
  xmlFree(buf);
  return rb_str;
}

/*
 * call-seq:
 *  read_memory(string, url, encoding, options)
 *
 * Read the HTML document contained in +string+ with given +url+, +encoding+,
 * and +options+.  See Nokogiri::HTML.parse
 */
static VALUE read_memory( VALUE klass,
                          VALUE string,
                          VALUE url,
                          VALUE encoding,
                          VALUE options )
{
  const char * c_buffer = StringValuePtr(string);
  const char * c_url    = (url == Qnil) ? NULL : StringValuePtr(url);
  const char * c_enc    = (encoding == Qnil) ? NULL : StringValuePtr(encoding);
  int len               = NUM2INT(rb_funcall(string, rb_intern("length"), 0));

  htmlDocPtr doc = htmlReadMemory(c_buffer, len, c_url, c_enc, NUM2INT(options));

  if(doc == NULL) {
    xmlFreeDoc(doc);
    rb_raise(rb_eRuntimeError, "Couldn't create a document");
    return Qnil;
  }

  return Nokogiri_wrap_xml_document(klass, doc);
}

/*
 * call-seq:
 *  type
 *
 * The type for this document
 */
static VALUE type(VALUE self)
{
  htmlDocPtr doc;
  Data_Get_Struct(self, xmlDoc, doc);
  return INT2NUM((int)doc->type);
}

VALUE cNokogiriHtmlDocument ;
void init_html_document()
{
  /*
   * HACK.  This is so that rdoc will work with this C file.
   */
  /*
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE html = rb_define_module_under(nokogiri, "HTML");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE node = rb_define_class_under(xml, "Node", rb_cObject);
  VALUE xml_doc = rb_define_class_under(xml, "Document", node);
  VALUE klass = rb_define_class_under(html, "Document", xml_doc);
  */

  VALUE klass ;
  klass = cNokogiriHtmlDocument = rb_const_get(mNokogiriHtml, rb_intern("Document"));

  rb_define_singleton_method(klass, "read_memory", read_memory, 4);

  rb_define_method(klass, "type", type, 0);
  rb_define_method(klass, "serialize", serialize, 0);
}
