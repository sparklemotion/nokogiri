#include <xml_document.h>

static void dealloc(xmlDocPtr doc)
{
  xmlFreeDoc(doc);
}

/*
 * call-seq:
 *  root
 *
 * Get the root node for this document.
 */
static VALUE root(VALUE self)
{
  xmlDocPtr doc;
  Data_Get_Struct(self, xmlDoc, doc);

  xmlNodePtr root = xmlDocGetRootElement(doc);

  if(!root) return Qnil;
  return Nokogiri_wrap_xml_node(root);
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
  int len               = rb_funcall(string, rb_intern("length"), 0);

  xmlInitParser();
  xmlDocPtr doc = xmlReadMemory(c_buffer, len, c_url, c_enc, NUM2INT(options));
  VALUE rb_doc = Data_Wrap_Struct(klass, NULL, dealloc, doc);
  doc->_private = (void *)rb_doc;
  return rb_doc;
}

static VALUE new(int argc, VALUE *argv, VALUE klass)
{
  VALUE version;
  if(rb_scan_args(argc, argv, "01", &version) == 0)
    version = rb_str_new2("1.0");

  xmlChar * xml_version = xmlCharStrdup(StringValuePtr(version));
  xmlDocPtr doc = xmlNewDoc(xml_version);
  free(xml_version);
  VALUE rb_doc = Data_Wrap_Struct(klass, NULL, dealloc, doc);
  doc->_private = (void *)rb_doc;
  return rb_doc;
}

void init_xml_document()
{
  VALUE m_nokogiri  = rb_const_get(rb_cObject, rb_intern("Nokogiri"));
  VALUE m_xml       = rb_const_get(m_nokogiri, rb_intern("XML"));
  VALUE klass       = rb_const_get(m_xml, rb_intern("Document"));

  rb_define_singleton_method(klass, "read_memory", read_memory, 4);
  rb_define_singleton_method(klass, "new", new, -1);
  rb_define_method(klass, "root", root, 0);
}
