#include <nokogiri.h>

VALUE mNokogiri ;
VALUE mNokogiriXml ;
VALUE mNokogiriHtml ;
VALUE mNokogiriXslt ;
VALUE mNokogiriXmlSax ;
VALUE mNokogiriHtmlSax ;

static ID id_read, id_write;


#ifndef HAVE_VASPRINTF
/*
 * Thank you Geoffroy Couprie for this implementation of vasprintf!
 */
int
vasprintf(char **strp, const char *fmt, va_list ap)
{
  /* Mingw32/64 have a broken vsnprintf implementation that fails when
   * using a zero-byte limit in order to retrieve the required size for malloc.
   * So we use a one byte buffer instead.
   */
  char tmp[1];
  int len = vsnprintf(tmp, 1, fmt, ap) + 1;
  char *res = (char *)malloc((unsigned int)len);
  if (res == NULL) {
    return -1;
  }
  *strp = res;
  return vsnprintf(res, (unsigned int)len, fmt, ap);
}
#endif

void
nokogiri_root_node(xmlNodePtr node)
{
  xmlDocPtr doc;
  nokogiriTuplePtr tuple;

  doc = node->doc;
  if (doc->type == XML_DOCUMENT_FRAG_NODE) { doc = doc->doc; }
  tuple = (nokogiriTuplePtr)doc->_private;
  st_insert(tuple->unlinkedNodes, (st_data_t)node, (st_data_t)node);
}

void
nokogiri_root_nsdef(xmlNsPtr ns, xmlDocPtr doc)
{
  nokogiriTuplePtr tuple;

  if (doc->type == XML_DOCUMENT_FRAG_NODE) { doc = doc->doc; }
  tuple = (nokogiriTuplePtr)doc->_private;
  st_insert(tuple->unlinkedNodes, (st_data_t)ns, (st_data_t)ns);
}


VALUE
read_check(VALUE val)
{
  VALUE *args = (VALUE *)val;
  return rb_funcall(args[0], id_read, 1, args[1]);
}


VALUE
read_failed(VALUE arg, VALUE exc)
{
  return Qundef;
}


int
io_read_callback(void *ctx, char *buffer, int len)
{
  VALUE string, args[2];
  size_t str_len, safe_len;

  args[0] = (VALUE)ctx;
  args[1] = INT2NUM(len);

  string = rb_rescue(read_check, (VALUE)args, read_failed, 0);

  if (NIL_P(string)) { return 0; }
  if (string == Qundef) { return -1; }
  if (TYPE(string) != T_STRING) { return -1; }

  str_len = (size_t)RSTRING_LEN(string);
  safe_len = str_len > (size_t)len ? (size_t)len : str_len;
  memcpy(buffer, StringValuePtr(string), safe_len);

  return (int)safe_len;
}


VALUE
write_check(VALUE val)
{
  VALUE *args = (VALUE *)val;
  return rb_funcall(args[0], id_write, 1, args[1]);
}


VALUE
write_failed(VALUE arg, VALUE exc)
{
  return Qundef;
}


int
io_write_callback(void *ctx, char *buffer, int len)
{
  VALUE args[2], size;

  args[0] = (VALUE)ctx;
  args[1] = rb_str_new(buffer, (long)len);

  size = rb_rescue(write_check, (VALUE)args, write_failed, 0);

  if (size == Qundef) { return -1; }

  return NUM2INT(size);
}


int
io_close_callback(void *ctx)
{
  return 0;
}


void
Init_nokogiri()
{
  xmlMemSetup(
    (xmlFreeFunc)ruby_xfree,
    (xmlMallocFunc)ruby_xmalloc,
    (xmlReallocFunc)ruby_xrealloc,
    ruby_strdup
  );

  mNokogiri         = rb_define_module("Nokogiri");
  mNokogiriXml      = rb_define_module_under(mNokogiri, "XML");
  mNokogiriHtml     = rb_define_module_under(mNokogiri, "HTML");
  mNokogiriXslt     = rb_define_module_under(mNokogiri, "XSLT");
  mNokogiriXmlSax   = rb_define_module_under(mNokogiriXml, "SAX");
  mNokogiriHtmlSax  = rb_define_module_under(mNokogiriHtml, "SAX");

  rb_const_set(mNokogiri, rb_intern("LIBXML_COMPILED_VERSION"), NOKOGIRI_STR_NEW2(LIBXML_DOTTED_VERSION));
  rb_const_set(mNokogiri, rb_intern("LIBXML_LOADED_VERSION"), NOKOGIRI_STR_NEW2(xmlParserVersion));

  rb_const_set(mNokogiri, rb_intern("LIBXSLT_COMPILED_VERSION"), NOKOGIRI_STR_NEW2(LIBXSLT_DOTTED_VERSION));
  rb_const_set(mNokogiri, rb_intern("LIBXSLT_LOADED_VERSION"), NOKOGIRI_STR_NEW2(xsltEngineVersion));

#ifdef NOKOGIRI_PACKAGED_LIBRARIES
  rb_const_set(mNokogiri, rb_intern("PACKAGED_LIBRARIES"), Qtrue);
#  ifdef NOKOGIRI_PRECOMPILED_LIBRARIES
  rb_const_set(mNokogiri, rb_intern("PRECOMPILED_LIBRARIES"), Qtrue);
#  else
  rb_const_set(mNokogiri, rb_intern("PRECOMPILED_LIBRARIES"), Qfalse);
#  endif
  rb_const_set(mNokogiri, rb_intern("LIBXML2_PATCHES"), rb_str_split(NOKOGIRI_STR_NEW2(NOKOGIRI_LIBXML2_PATCHES), " "));
  rb_const_set(mNokogiri, rb_intern("LIBXSLT_PATCHES"), rb_str_split(NOKOGIRI_STR_NEW2(NOKOGIRI_LIBXSLT_PATCHES), " "));
#else
  rb_const_set(mNokogiri, rb_intern("PACKAGED_LIBRARIES"), Qfalse);
  rb_const_set(mNokogiri, rb_intern("PRECOMPILED_LIBRARIES"), Qfalse);
  rb_const_set(mNokogiri, rb_intern("LIBXML2_PATCHES"), Qnil);
  rb_const_set(mNokogiri, rb_intern("LIBXSLT_PATCHES"), Qnil);
#endif

#ifdef LIBXML_ICONV_ENABLED
  rb_const_set(mNokogiri, rb_intern("LIBXML_ICONV_ENABLED"), Qtrue);
#else
  rb_const_set(mNokogiri, rb_intern("LIBXML_ICONV_ENABLED"), Qfalse);
#endif

#ifdef NOKOGIRI_OTHER_LIBRARY_VERSIONS
  rb_const_set(mNokogiri, rb_intern("OTHER_LIBRARY_VERSIONS"), NOKOGIRI_STR_NEW2(NOKOGIRI_OTHER_LIBRARY_VERSIONS));
#endif

  xmlInitParser();

  init_xml_document();
  init_html_document();
  init_xml_node();
  init_xml_document_fragment();
  init_xml_text();
  init_xml_cdata();
  init_xml_processing_instruction();
  init_xml_attr();
  init_xml_entity_reference();
  init_xml_comment();
  init_xml_node_set();
  init_xml_xpath_context();
  init_xml_sax_parser_context();
  init_xml_sax_parser();
  init_xml_sax_push_parser();
  init_xml_reader();
  init_xml_dtd();
  init_xml_element_content();
  init_xml_attribute_decl();
  init_xml_element_decl();
  init_xml_entity_decl();
  init_xml_namespace();
  init_html_sax_parser_context();
  init_html_sax_push_parser();
  init_xslt_stylesheet();
  init_xml_syntax_error();
  init_html_entity_lookup();
  init_html_element_description();
  init_xml_schema();
  init_xml_relax_ng();
  init_xml_encoding_handler();
  init_test_global_handlers();

  id_read = rb_intern("read");
  id_write = rb_intern("write");
}
