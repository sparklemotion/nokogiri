#include <nokogiri.h>

VALUE mNokogiri ;
VALUE mNokogiriGumbo ;
VALUE mNokogiriHtml4 ;
VALUE mNokogiriHtml4Sax ;
VALUE mNokogiriHtml5 ;
VALUE mNokogiriXml ;
VALUE mNokogiriXmlSax ;
VALUE mNokogiriXmlXpath ;
VALUE mNokogiriXslt ;

VALUE cNokogiriSyntaxError;
VALUE cNokogiriXmlCharacterData;
VALUE cNokogiriXmlElement;
VALUE cNokogiriXmlXpathSyntaxError;

void noko_init_xml_attr(void);
void noko_init_xml_attribute_decl(void);
void noko_init_xml_cdata(void);
void noko_init_xml_comment(void);
void noko_init_xml_document(void);
void noko_init_xml_document_fragment(void);
void noko_init_xml_dtd(void);
void noko_init_xml_element_content(void);
void noko_init_xml_element_decl(void);
void noko_init_xml_encoding_handler(void);
void noko_init_xml_entity_decl(void);
void noko_init_xml_entity_reference(void);
void noko_init_xml_namespace(void);
void noko_init_xml_node(void);
void noko_init_xml_node_set(void);
void noko_init_xml_processing_instruction(void);
void noko_init_xml_reader(void);
void noko_init_xml_relax_ng(void);
void noko_init_xml_sax_parser(void);
void noko_init_xml_sax_parser_context(void);
void noko_init_xml_sax_push_parser(void);
void noko_init_xml_schema(void);
void noko_init_xml_syntax_error(void);
void noko_init_xml_text(void);
void noko_init_xml_xpath_context(void);
void noko_init_xslt_stylesheet(void);
void noko_init_html_document(void);
void noko_init_html_element_description(void);
void noko_init_html_entity_lookup(void);
void noko_init_html_sax_parser_context(void);
void noko_init_html_sax_push_parser(void);
void noko_init_html4_sax_parser(void);
void noko_init_gumbo(void);
void noko_init_test_global_handlers(void);

static ID id_read, id_write, id_external_encoding, id_io_read_exception;


static VALUE
noko_io_read_check(VALUE val)
{
  VALUE *args = (VALUE *)val;
  return rb_funcall(args[0], id_read, 1, args[1]);
}


static VALUE
noko_io_read_failed(VALUE arg, VALUE exc)
{
  return Qundef;
}


int
noko_io_read(void *io, char *c_buffer, int c_buffer_len)
{
  VALUE rb_io = (VALUE)io;
  VALUE rb_read_string, rb_args[2];
  size_t n_bytes_read, safe_len;

  rb_args[0] = rb_io;
  rb_args[1] = INT2NUM(c_buffer_len);

  rb_read_string = rb_rescue(noko_io_read_check, (VALUE)rb_args, noko_io_read_failed, 0);

  if (NIL_P(rb_read_string)) { return 0; }
  if (rb_read_string == Qundef) { return -1; }
  if (TYPE(rb_read_string) != T_STRING) { return -1; }

  n_bytes_read = (size_t)RSTRING_LEN(rb_read_string);
  safe_len = (n_bytes_read > (size_t)c_buffer_len) ? (size_t)c_buffer_len : n_bytes_read;
  memcpy(c_buffer, StringValuePtr(rb_read_string), safe_len);

  return (int)safe_len;
}


typedef struct {
  void *io;
  char *c_buffer;
  int c_buffer_len;
  int n_bytes_read;
} noko_io_read_args_t;

static VALUE
noko_io_read_call(VALUE data)
{
  noko_io_read_args_t *args = (noko_io_read_args_t *)data;
  args->n_bytes_read = noko_io_read(args->io, args->c_buffer, args->c_buffer_len);
  return Qnil;
}


/*
 * Like noko_io_read, a StandardError raised by IO#read is swallowed, and libxml2 sees a read
 * error. Any other exception (e.g., Interrupt or Timeout::ExitException) must not unwind through
 * libxml2's stack frames, because that skips libxml2's cleanup and leaks memory, and skips the
 * reset of the error handlers. So it is saved in a fiber-local variable, and $! is cleared until
 * it is re-raised.
 *
 * A caller of libxml2 that passes this callback must call noko_io_read_reset_exception before
 * calling libxml2, and noko_io_read_take_exception after libxml2 returns, and must re-raise a
 * non-nil result with noko_io_read_raise_exception.
 */
int
noko_io_read_protected(void *io, char *c_buffer, int c_buffer_len)
{
  noko_io_read_args_t args = { io, c_buffer, c_buffer_len, -1 };
  int state = 0;

  rb_protect(noko_io_read_call, (VALUE)&args, &state);

  if (state) {
    VALUE rb_errinfo_value = rb_errinfo();
    if (RB_TYPE_P(rb_errinfo_value, T_OBJECT) && rb_obj_is_kind_of(rb_errinfo_value, rb_eException)) {
      rb_set_errinfo(Qnil);
    } else {
      rb_errinfo_value = Qnil;
    }
    rb_thread_local_aset(rb_thread_current(), id_io_read_exception,
                         rb_assoc_new(INT2FIX(state), rb_errinfo_value));
    return -1;
  }

  return args.n_bytes_read;
}


void
noko_io_read_reset_exception(void)
{
  rb_thread_local_aset(rb_thread_current(), id_io_read_exception, Qnil);
}


VALUE
noko_io_read_take_exception(void)
{
  VALUE rb_thread = rb_thread_current();
  VALUE rb_exception = rb_thread_local_aref(rb_thread, id_io_read_exception);

  rb_thread_local_aset(rb_thread, id_io_read_exception, Qnil);
  return rb_exception;
}


void
noko_io_read_raise_exception(VALUE rb_exception)
{
  VALUE rb_errinfo_value = rb_ary_entry(rb_exception, 1);

  if (!NIL_P(rb_errinfo_value)) {
    rb_set_errinfo(rb_errinfo_value);
  }
  rb_jump_tag(FIX2INT(rb_ary_entry(rb_exception, 0)));
}


static VALUE
noko_io_write_check(VALUE rb_args)
{
  VALUE rb_io = ((VALUE *)rb_args)[0];
  VALUE rb_output = ((VALUE *)rb_args)[1];
  return rb_funcall(rb_io, id_write, 1, rb_output);
}


static VALUE
noko_io_write_failed(VALUE arg, VALUE exc)
{
  return Qundef;
}


int
noko_io_write(void *io, char *c_buffer, int c_buffer_len)
{
  VALUE rb_args[2], rb_n_bytes_written;
  VALUE rb_io = (VALUE)io;
  VALUE rb_enc = Qnil;
  rb_encoding *io_encoding;

  if (rb_respond_to(rb_io, id_external_encoding)) {
    rb_enc = rb_funcall(rb_io, id_external_encoding, 0);
  }
  io_encoding = RB_NIL_P(rb_enc) ? rb_ascii8bit_encoding() : rb_to_encoding(rb_enc);

  rb_args[0] = rb_io;
  rb_args[1] = rb_enc_str_new(c_buffer, (rb_len_t)c_buffer_len, io_encoding);

  rb_n_bytes_written = rb_rescue(noko_io_write_check, (VALUE)rb_args, noko_io_write_failed, 0);
  if (rb_n_bytes_written == Qundef) { return -1; }

  return NUM2INT(rb_n_bytes_written);
}


int
noko_io_close(void *io)
{
  return 0;
}


#if defined(_WIN32) && !defined(NOKOGIRI_PACKAGED_LIBRARIES)
#  define NOKOGIRI_WINDOWS_DLLS 1
#else
#  define NOKOGIRI_WINDOWS_DLLS 0
#endif

//
//   |      dlls || true    | false   |
//   | nlmm      ||         |         |
//   |-----------++---------+---------|
//   | NULL      || default | ruby    |
//   | "random"  || default | ruby    |
//   | "ruby"    || ruby    | ruby    |
//   | "default" || default | default |
//
//   We choose *not* to use Ruby's memory management functions with windows DLLs because of this
//   issue: https://github.com/sparklemotion/nokogiri/issues/2241
//
static void
set_libxml_memory_management(void)
{
  const char *nlmm = getenv("NOKOGIRI_LIBXML_MEMORY_MANAGEMENT");
  if (nlmm) {
    if (strcmp(nlmm, "default") == 0) {
      goto libxml_uses_default_memory_management;
    } else if (strcmp(nlmm, "ruby") == 0) {
      goto libxml_uses_ruby_memory_management;
    }
  }
  if (NOKOGIRI_WINDOWS_DLLS) {
libxml_uses_default_memory_management:
    rb_const_set(mNokogiri, rb_intern("LIBXML_MEMORY_MANAGEMENT"), NOKOGIRI_STR_NEW2("default"));
    return;
  } else {
libxml_uses_ruby_memory_management:
    rb_const_set(mNokogiri, rb_intern("LIBXML_MEMORY_MANAGEMENT"), NOKOGIRI_STR_NEW2("ruby"));
    xmlMemSetup((xmlFreeFunc)ruby_xfree, (xmlMallocFunc)ruby_xmalloc, (xmlReallocFunc)ruby_xrealloc, ruby_strdup);
    return;
  }
}


void
Init_nokogiri(void)
{
  mNokogiri         = rb_define_module("Nokogiri");
  mNokogiriGumbo    = rb_define_module_under(mNokogiri, "Gumbo");
  mNokogiriHtml4    = rb_define_module_under(mNokogiri, "HTML4");
  mNokogiriHtml4Sax = rb_define_module_under(mNokogiriHtml4, "SAX");
  mNokogiriHtml5    = rb_define_module_under(mNokogiri, "HTML5");
  mNokogiriXml      = rb_define_module_under(mNokogiri, "XML");
  mNokogiriXmlSax   = rb_define_module_under(mNokogiriXml, "SAX");
  mNokogiriXmlXpath = rb_define_module_under(mNokogiriXml, "XPath");
  mNokogiriXslt     = rb_define_module_under(mNokogiri, "XSLT");

  set_libxml_memory_management(); /* must be before any function calls that might invoke xmlInitParser() */
  xmlInitParser();
  exsltRegisterAll();

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

  rb_const_set(mNokogiri, rb_intern("LIBXML_ZLIB_ENABLED"),
               xmlHasFeature(XML_WITH_ZLIB) == 1 ? Qtrue : Qfalse);

  rb_const_set(mNokogiri, rb_intern("LIBXML_HTTP_ENABLED"),
               xmlHasFeature(XML_WITH_HTTP) == 1 ? Qtrue : Qfalse);

#ifdef NOKOGIRI_OTHER_LIBRARY_VERSIONS
  rb_const_set(mNokogiri, rb_intern("OTHER_LIBRARY_VERSIONS"), NOKOGIRI_STR_NEW2(NOKOGIRI_OTHER_LIBRARY_VERSIONS));
#endif

  if (xsltExtModuleFunctionLookup((const xmlChar *)"date-time", EXSLT_DATE_NAMESPACE)) {
    rb_const_set(mNokogiri, rb_intern("LIBXSLT_DATETIME_ENABLED"), Qtrue);
  } else {
    rb_const_set(mNokogiri, rb_intern("LIBXSLT_DATETIME_ENABLED"), Qfalse);
  }

  cNokogiriSyntaxError = rb_define_class_under(mNokogiri, "SyntaxError", rb_eStandardError);
  noko_init_xml_syntax_error();
  assert(cNokogiriXmlSyntaxError);
  cNokogiriXmlXpathSyntaxError = rb_define_class_under(mNokogiriXmlXpath, "SyntaxError", cNokogiriXmlSyntaxError);

  noko_init_xml_element_content();
  noko_init_xml_encoding_handler();
  noko_init_xml_namespace();
  noko_init_xml_node_set();
  noko_init_xml_reader();

  noko_init_xml_sax_parser();
  noko_init_html4_sax_parser();

  noko_init_xml_xpath_context();
  noko_init_xslt_stylesheet();
  noko_init_html_element_description();
  noko_init_html_entity_lookup();

  noko_init_xml_schema();
  noko_init_xml_relax_ng();

  noko_init_xml_sax_parser_context();
  noko_init_html_sax_parser_context();

  noko_init_xml_sax_push_parser();
  noko_init_html_sax_push_parser();

  noko_init_xml_node();
  noko_init_xml_attr();
  noko_init_xml_attribute_decl();
  noko_init_xml_dtd();
  noko_init_xml_element_decl();
  noko_init_xml_entity_decl();
  noko_init_xml_entity_reference();
  noko_init_xml_processing_instruction();
  assert(cNokogiriXmlNode);
  cNokogiriXmlElement = rb_define_class_under(mNokogiriXml, "Element", cNokogiriXmlNode);
  cNokogiriXmlCharacterData = rb_define_class_under(mNokogiriXml, "CharacterData", cNokogiriXmlNode);
  noko_init_xml_comment();
  noko_init_xml_text();
  noko_init_xml_cdata();

  noko_init_xml_document_fragment();
  noko_init_xml_document();
  noko_init_html_document();
  noko_init_gumbo();

  noko_init_test_global_handlers();

  id_read = rb_intern("read");
  id_io_read_exception = rb_intern("__nokogiri_io_read_exception");
  id_write = rb_intern("write");
  id_external_encoding = rb_intern("external_encoding");
}
