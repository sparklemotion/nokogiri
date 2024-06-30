#include <nokogiri.h>

VALUE cNokogiriXmlSaxParserContext ;

static ID id_read;

static void
xml_sax_parser_context_type_free(void *data)
{
  xmlParserCtxtPtr ctxt = data;
  ctxt->sax = NULL;
  xmlFreeParserCtxt(ctxt);
}

/*
 *  note that htmlParserCtxtPtr == xmlParserCtxtPtr and xmlFreeParserCtxt() == htmlFreeParserCtxt()
 *  so we use this type for both XML::SAX::ParserContext and HTML::SAX::ParserContext
 */
static const rb_data_type_t xml_sax_parser_context_type = {
  .wrap_struct_name = "xmlParserCtxt",
  .function = {
    .dfree = xml_sax_parser_context_type_free,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

xmlParserCtxtPtr
noko_xml_sax_parser_context_unwrap(VALUE rb_context)
{
  xmlParserCtxtPtr c_context;
  TypedData_Get_Struct(rb_context, xmlParserCtxt, &xml_sax_parser_context_type, c_context);
  return c_context;
}

VALUE
noko_xml_sax_parser_context_wrap(VALUE klass, xmlParserCtxtPtr c_context)
{
  return TypedData_Wrap_Struct(klass, &xml_sax_parser_context_type, c_context);
}


/*
 * call-seq:
 *  parse_io(io, encoding)
 *
 * Parse +io+ object with +encoding+
 */
static VALUE
noko_xml_sax_parser_context_s_io(VALUE rb_class, VALUE rb_io, VALUE rb_encoding_id)
{
  xmlParserCtxtPtr c_context;
  xmlCharEncoding c_encoding = (xmlCharEncoding)NUM2INT(rb_encoding_id);

  if (!rb_respond_to(rb_io, id_read)) {
    rb_raise(rb_eTypeError, "argument expected to respond to :read");
  }

  c_context = xmlCreateIOParserCtxt(NULL, NULL,
                                    (xmlInputReadCallback)noko_io_read,
                                    (xmlInputCloseCallback)noko_io_close,
                                    (void *)rb_io, c_encoding);
  if (!c_context) {
    rb_raise(rb_eRuntimeError, "failed to create xml sax parser context");
  }

  if (c_context->sax) {
    xmlFree(c_context->sax);
    c_context->sax = NULL;
  }

  return noko_xml_sax_parser_context_wrap(rb_class, c_context);
}

/*
 * call-seq:
 *  parse_file(filename)
 *
 * Parse file given +filename+
 */
static VALUE
noko_xml_sax_parser_context_s_file(VALUE rb_class, VALUE rb_path)
{
  xmlParserCtxtPtr c_context = xmlCreateFileParserCtxt(StringValueCStr(rb_path));

  if (c_context->sax) {
    xmlFree(c_context->sax);
    c_context->sax = NULL;
  }

  return noko_xml_sax_parser_context_wrap(rb_class, c_context);
}

/*
 * call-seq:
 *  parse_memory(data)
 *
 * Parse the XML stored in memory in +data+
 */
static VALUE
noko_xml_sax_parser_context_s_memory(VALUE rb_class, VALUE rb_input)
{
  xmlParserCtxtPtr c_context;

  Check_Type(rb_input, T_STRING);

  if (!(int)RSTRING_LEN(rb_input)) {
    rb_raise(rb_eRuntimeError, "input string cannot be empty");
  }

  c_context = xmlCreateMemoryParserCtxt(StringValuePtr(rb_input),
                                        (int)RSTRING_LEN(rb_input));
  if (c_context->sax) {
    xmlFree(c_context->sax);
    c_context->sax = NULL;
  }

  return noko_xml_sax_parser_context_wrap(rb_class, c_context);
}

static VALUE
xml_sax_parser_context_parse_doc(VALUE ctxt_val)
{
  xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr)ctxt_val;
  xmlParseDocument(ctxt);
  return Qnil;
}

static VALUE
xml_sax_parser_context_parse_doc_finalize(VALUE ctxt_val)
{
  xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr)ctxt_val;

  if (NULL != ctxt->myDoc) {
    xmlFreeDoc(ctxt->myDoc);
  }

  NOKOGIRI_SAX_TUPLE_DESTROY(ctxt->userData);
  return Qnil;
}

/*
 * call-seq:
 *  parse_with(sax_handler)
 *
 * Use +sax_handler+ and parse the current document
 */
static VALUE
noko_xml_sax_parser_context__parse_with(VALUE rb_context, VALUE rb_sax_parser)
{
  xmlParserCtxtPtr c_context;
  xmlSAXHandlerPtr sax;

  if (!rb_obj_is_kind_of(rb_sax_parser, cNokogiriXmlSaxParser)) {
    rb_raise(rb_eArgError, "argument must be a Nokogiri::XML::SAX::Parser");
  }

  c_context = noko_xml_sax_parser_context_unwrap(rb_context);
  sax = noko_xml_sax_parser_unwrap(rb_sax_parser);

  c_context->sax = sax;
  c_context->userData = (void *)NOKOGIRI_SAX_TUPLE_NEW(c_context, rb_sax_parser);

  xmlSetStructuredErrorFunc(NULL, NULL);

  rb_ensure(
    xml_sax_parser_context_parse_doc, (VALUE)c_context,
    xml_sax_parser_context_parse_doc_finalize, (VALUE)c_context
  );

  return Qnil;
}

/*
 * call-seq:
 *  replace_entities=(boolean)
 *
 * Should this parser replace entities?  &amp; will get converted to '&' if
 * set to true
 */
static VALUE
noko_xml_sax_parser_context__replace_entities_set(VALUE rb_context, VALUE rb_value)
{
  int error;
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(rb_context);

  if (RB_TEST(rb_value)) {
    error = xmlCtxtSetOptions(ctxt, xmlCtxtGetOptions(ctxt) | XML_PARSE_NOENT);
  } else {
    error = xmlCtxtSetOptions(ctxt, xmlCtxtGetOptions(ctxt) & ~XML_PARSE_NOENT);
  }

  if (error) {
    rb_raise(rb_eRuntimeError, "failed to set parser context options (%x)", error);
  }

  return rb_value;
}

/*
 * call-seq:
 *  replace_entities
 *
 * Should this parser replace entities?  &amp; will get converted to '&' if
 * set to true
 */
static VALUE
noko_xml_sax_parser_context__replace_entities_get(VALUE rb_context)
{
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(rb_context);

  if (xmlCtxtGetOptions(ctxt) & XML_PARSE_NOENT) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

/*
 * call-seq: line
 *
 * Get the current line the parser context is processing.
 */
static VALUE
noko_xml_sax_parser_context__line(VALUE rb_context)
{
  xmlParserInputPtr io;
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(rb_context);

  io = ctxt->input;
  if (io) {
    return INT2NUM(io->line);
  }

  return Qnil;
}

/*
 * call-seq: column
 *
 * Get the current column the parser context is processing.
 */
static VALUE
noko_xml_sax_parser_context__column(VALUE rb_context)
{
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(rb_context);
  xmlParserInputPtr io;

  io = ctxt->input;
  if (io) {
    return INT2NUM(io->col);
  }

  return Qnil;
}

/*
 * call-seq:
 *  recovery=(boolean)
 *
 * Should this parser recover from structural errors? It will not stop processing
 * file on structural errors if set to true
 */
static VALUE
noko_xml_sax_parser_context__recovery_set(VALUE rb_context, VALUE rb_value)
{
  int error;
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(rb_context);

  if (RB_TEST(rb_value)) {
    error = xmlCtxtSetOptions(ctxt, xmlCtxtGetOptions(ctxt) | XML_PARSE_RECOVER);
  } else {
    error = xmlCtxtSetOptions(ctxt, xmlCtxtGetOptions(ctxt) & ~XML_PARSE_RECOVER);
  }

  if (error) {
    rb_raise(rb_eRuntimeError, "failed to set parser context options (%x)", error);
  }

  return rb_value;
}

/*
 * call-seq:
 *  recovery
 *
 * Should this parser recover from structural errors? It will not stop processing
 * file on structural errors if set to true
 */
static VALUE
noko_xml_sax_parser_context__recovery_get(VALUE rb_context)
{
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(rb_context);

  if (xmlCtxtGetOptions(ctxt) & XML_PARSE_RECOVER) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

void
noko_init_xml_sax_parser_context(void)
{
  cNokogiriXmlSaxParserContext = rb_define_class_under(mNokogiriXmlSax, "ParserContext", rb_cObject);

  rb_undef_alloc_func(cNokogiriXmlSaxParserContext);

  rb_define_singleton_method(cNokogiriXmlSaxParserContext, "io", noko_xml_sax_parser_context_s_io, 2);
  rb_define_singleton_method(cNokogiriXmlSaxParserContext, "memory", noko_xml_sax_parser_context_s_memory, 1);
  rb_define_singleton_method(cNokogiriXmlSaxParserContext, "file", noko_xml_sax_parser_context_s_file, 1);

  rb_define_method(cNokogiriXmlSaxParserContext, "parse_with", noko_xml_sax_parser_context__parse_with, 1);
  rb_define_method(cNokogiriXmlSaxParserContext, "replace_entities=",
                   noko_xml_sax_parser_context__replace_entities_set, 1);
  rb_define_method(cNokogiriXmlSaxParserContext, "replace_entities",
                   noko_xml_sax_parser_context__replace_entities_get, 0);
  rb_define_method(cNokogiriXmlSaxParserContext, "recovery=", noko_xml_sax_parser_context__recovery_set, 1);
  rb_define_method(cNokogiriXmlSaxParserContext, "recovery", noko_xml_sax_parser_context__recovery_get, 0);
  rb_define_method(cNokogiriXmlSaxParserContext, "line", noko_xml_sax_parser_context__line, 0);
  rb_define_method(cNokogiriXmlSaxParserContext, "column", noko_xml_sax_parser_context__column, 0);

  id_read = rb_intern("read");
}
