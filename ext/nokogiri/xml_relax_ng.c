#include <nokogiri.h>

VALUE cNokogiriXmlRelaxNG;

static void
dealloc(xmlRelaxNGPtr schema)
{
  NOKOGIRI_DEBUG_START(schema);
  xmlRelaxNGFree(schema);
  NOKOGIRI_DEBUG_END(schema);
}


static VALUE
rb_xml_relax_ng_validate_document(VALUE self, VALUE document)
{
  xmlDocPtr doc;
  xmlRelaxNGPtr schema;
  VALUE errors;
  xmlRelaxNGValidCtxtPtr valid_ctxt;

  Data_Get_Struct(self, xmlRelaxNG, schema);
  Data_Get_Struct(document, xmlDoc, doc);

  errors = rb_ary_new();

  valid_ctxt = xmlRelaxNGNewValidCtxt(schema);

  if (NULL == valid_ctxt) {
    /* we have a problem */
    rb_raise(rb_eRuntimeError, "Could not create a validation context");
  }

#ifdef HAVE_XMLRELAXNGSETVALIDSTRUCTUREDERRORS
  xmlRelaxNGSetValidStructuredErrors(
    valid_ctxt,
    Nokogiri_error_array_pusher,
    (void *)errors
  );
#endif

  xmlRelaxNGValidateDoc(valid_ctxt, doc);

  xmlRelaxNGFreeValidCtxt(valid_ctxt);

  return errors;
}


/*
 * :call-seq:
 *   read_memory(input) → Nokogiri::XML::RelaxNG
 *   read_memory(input, parse_options) → Nokogiri::XML::RelaxNG
 *
 * Parse a RELAX NG schema definition and create a new Schema object.
 *
 * 💡 Note that the limitation of this method relative to RelaxNG.new is that +input+ must be type
 * String, whereas RelaxNG.new also supports IO types.
 *
 * [Parameters]
 * - +input+ (String) RELAX NG schema definition
 * - +parse_options+ (Nokogiri::XML::ParseOptions) Defaults to ParseOptions::DEFAULT_SCHEMA
 *
 * [Returns] Nokogiri::XML::RelaxNG
 */
static VALUE
rb_xml_relax_ng_s_read_memory(int argc, VALUE *argv, VALUE klass)
{
  VALUE content;
  VALUE parse_options;
  xmlRelaxNGParserCtxtPtr ctx;
  xmlRelaxNGPtr schema;
  VALUE errors;
  VALUE rb_schema;
  int scanned_args = 0;

  scanned_args = rb_scan_args(argc, argv, "11", &content, &parse_options);
  if (scanned_args == 1) {
    parse_options = rb_const_get_at(rb_const_get_at(mNokogiriXml, rb_intern("ParseOptions")), rb_intern("DEFAULT_SCHEMA"));
  }

  ctx = xmlRelaxNGNewMemParserCtxt((const char *)StringValuePtr(content), (int)RSTRING_LEN(content));

  errors = rb_ary_new();
  xmlSetStructuredErrorFunc((void *)errors, Nokogiri_error_array_pusher);

#ifdef HAVE_XMLRELAXNGSETPARSERSTRUCTUREDERRORS
  xmlRelaxNGSetParserStructuredErrors(
    ctx,
    Nokogiri_error_array_pusher,
    (void *)errors
  );
#endif

  schema = xmlRelaxNGParse(ctx);

  xmlSetStructuredErrorFunc(NULL, NULL);
  xmlRelaxNGFreeParserCtxt(ctx);

  if (NULL == schema) {
    xmlErrorPtr error = xmlGetLastError();
    if (error) {
      Nokogiri_error_raise(NULL, error);
    } else {
      rb_raise(rb_eRuntimeError, "Could not parse document");
    }

    return Qnil;
  }

  rb_schema = Data_Wrap_Struct(klass, 0, dealloc, schema);
  rb_iv_set(rb_schema, "@errors", errors);
  rb_iv_set(rb_schema, "@parse_options", parse_options);

  return rb_schema;
}


/*
 * :call-seq:
 *   from_document(document) → Nokogiri::XML::RelaxNG
 *   from_document(document, parse_options) → Nokogiri::XML::RelaxNG
 *
 * Create a Schema from an already-parsed RELAX NG schema definition document.
 *
 * [Parameters]
 * - +document+ (XML::Document) A XML::Document object representing the parsed RELAX NG
 * - +parse_options+ (Nokogiri::XML::ParseOptions) ⚠ Unused
 *
 * [Returns] Nokogiri::XML::RelaxNG
 *
 * ⚠ +parse_options+ is currently unused by this method and is present only as a placeholder for
 * future functionality.
 */
static VALUE
rb_xml_relax_ng_s_from_document(int argc, VALUE *argv, VALUE klass)
{
  VALUE document;
  VALUE parse_options;
  xmlDocPtr doc;
  xmlRelaxNGParserCtxtPtr ctx;
  xmlRelaxNGPtr schema;
  VALUE errors;
  VALUE rb_schema;
  int scanned_args = 0;

  scanned_args = rb_scan_args(argc, argv, "11", &document, &parse_options);

  Data_Get_Struct(document, xmlDoc, doc);
  doc = doc->doc; /* In case someone passes us a node. ugh. */

  if (scanned_args == 1) {
    parse_options = rb_const_get_at(rb_const_get_at(mNokogiriXml, rb_intern("ParseOptions")), rb_intern("DEFAULT_SCHEMA"));
  }

  ctx = xmlRelaxNGNewDocParserCtxt(doc);

  errors = rb_ary_new();
  xmlSetStructuredErrorFunc((void *)errors, Nokogiri_error_array_pusher);

#ifdef HAVE_XMLRELAXNGSETPARSERSTRUCTUREDERRORS
  xmlRelaxNGSetParserStructuredErrors(
    ctx,
    Nokogiri_error_array_pusher,
    (void *)errors
  );
#endif

  schema = xmlRelaxNGParse(ctx);

  xmlSetStructuredErrorFunc(NULL, NULL);
  xmlRelaxNGFreeParserCtxt(ctx);

  if (NULL == schema) {
    xmlErrorPtr error = xmlGetLastError();
    if (error) {
      Nokogiri_error_raise(NULL, error);
    } else {
      rb_raise(rb_eRuntimeError, "Could not parse document");
    }

    return Qnil;
  }

  rb_schema = Data_Wrap_Struct(klass, 0, dealloc, schema);
  rb_iv_set(rb_schema, "@errors", errors);
  rb_iv_set(rb_schema, "@parse_options", parse_options);

  return rb_schema;
}

void
noko_init_xml_relax_ng()
{
  assert(cNokogiriXmlSchema);
  cNokogiriXmlRelaxNG = rb_define_class_under(mNokogiriXml, "RelaxNG", cNokogiriXmlSchema);

  rb_define_singleton_method(cNokogiriXmlRelaxNG, "read_memory", rb_xml_relax_ng_s_read_memory, -1);
  rb_define_singleton_method(cNokogiriXmlRelaxNG, "from_document", rb_xml_relax_ng_s_from_document, -1);

  rb_define_private_method(cNokogiriXmlRelaxNG, "validate_document", rb_xml_relax_ng_validate_document, 1);
}
