#include <html_document.h>

/*
 * call-seq:
 *  new
 *
 * Create a new document
 */
static VALUE new(int argc, VALUE *argv, VALUE klass)
{
  VALUE uri, external_id, rest, rb_doc;

  rb_scan_args(argc, argv, "0*", &rest);
  uri         = rb_ary_entry(rest, 0);
  external_id = rb_ary_entry(rest, 1);

  htmlDocPtr doc = htmlNewDoc(
      RTEST(uri) ? (const xmlChar *)StringValuePtr(uri) : NULL,
      RTEST(external_id) ? (const xmlChar *)StringValuePtr(external_id) : NULL
  );
  rb_doc = Nokogiri_wrap_xml_document(klass, doc);
  rb_funcall2(rb_doc, rb_intern("initialize"), argc, argv);
  return rb_doc ;
}

/*
 * call-seq:
 *  read_io(io, url, encoding, options)
 *
 * Read the HTML document from +io+ with given +url+, +encoding+,
 * and +options+.  See Nokogiri::HTML.parse
 */
static VALUE read_io( VALUE klass,
                      VALUE io,
                      VALUE url,
                      VALUE encoding,
                      VALUE options )
{
  const char * c_url    = (url == Qnil) ? NULL : StringValuePtr(url);
  const char * c_enc    = (encoding == Qnil) ? NULL : StringValuePtr(encoding);
  VALUE error_list      = rb_ary_new();

  xmlResetLastError();
  xmlSetStructuredErrorFunc((void *)error_list, Nokogiri_error_array_pusher);

  htmlDocPtr doc = htmlReadIO(
      io_read_callback,
      io_close_callback,
      (void *)io,
      c_url,
      c_enc,
      NUM2INT(options)
  );
  xmlSetStructuredErrorFunc(NULL, NULL);

  if(doc == NULL) {
    xmlFreeDoc(doc);

    xmlErrorPtr error = xmlGetLastError();
    if(error)
      rb_funcall(rb_mKernel, rb_intern("raise"), 1,
          Nokogiri_wrap_xml_syntax_error((VALUE)NULL, error)
      );
    else
      rb_raise(rb_eRuntimeError, "Could not parse document");

    return Qnil;
  }

  VALUE document = Nokogiri_wrap_xml_document(klass, doc);
  rb_funcall(document, rb_intern("errors="), 1, error_list);
  return document;
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
  int len               = RSTRING_LEN(string);
  VALUE error_list      = rb_ary_new();

  xmlResetLastError();
  xmlSetStructuredErrorFunc((void *)error_list, Nokogiri_error_array_pusher);

  htmlDocPtr doc = htmlReadMemory(c_buffer, len, c_url, c_enc, NUM2INT(options));
  xmlSetStructuredErrorFunc(NULL, NULL);

  if(doc == NULL) {
    xmlFreeDoc(doc);

    xmlErrorPtr error = xmlGetLastError();
    if(error)
      rb_funcall(rb_mKernel, rb_intern("raise"), 1,
          Nokogiri_wrap_xml_syntax_error((VALUE)NULL, error)
      );
    else
      rb_raise(rb_eRuntimeError, "Could not parse document");

    return Qnil;
  }

  VALUE document = Nokogiri_wrap_xml_document(klass, doc);
  rb_funcall(document, rb_intern("errors="), 1, error_list);
  return document;
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

/*
 * call-seq:
 *  meta_encoding=
 *
 * Set the meta tag encoding for this document.
 */
static VALUE set_meta_encoding(VALUE self, VALUE encoding)
{
  htmlDocPtr doc;
  Data_Get_Struct(self, xmlDoc, doc);

  htmlSetMetaEncoding(doc, (const xmlChar *)StringValuePtr(encoding));

  return encoding;
}

/*
 * call-seq:
 *  meta_encoding
 *
 * Get the meta tag encoding for this document.
 */
static VALUE meta_encoding(VALUE self)
{
  htmlDocPtr doc;
  Data_Get_Struct(self, xmlDoc, doc);

  return NOKOGIRI_STR_NEW2(htmlGetMetaEncoding(doc), doc->encoding);
}

VALUE cNokogiriHtmlDocument ;
void init_html_document()
{
  VALUE nokogiri  = rb_define_module("Nokogiri");
  VALUE html      = rb_define_module_under(nokogiri, "HTML");
  VALUE xml       = rb_define_module_under(nokogiri, "XML");
  VALUE node      = rb_define_class_under(xml, "Node", rb_cObject);
  VALUE xml_doc   = rb_define_class_under(xml, "Document", node);
  VALUE klass     = rb_define_class_under(html, "Document", xml_doc);

  cNokogiriHtmlDocument = klass;

  rb_define_singleton_method(klass, "read_memory", read_memory, 4);
  rb_define_singleton_method(klass, "read_io", read_io, 4);
  rb_define_singleton_method(klass, "new", new, -1);

  rb_define_method(klass, "type", type, 0);
  rb_define_method(klass, "meta_encoding", meta_encoding, 0);
  rb_define_method(klass, "meta_encoding=", set_meta_encoding, 1);
}
