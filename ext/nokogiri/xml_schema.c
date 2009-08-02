#include <xml_schema.h>

static void dealloc(xmlSchemaPtr schema)
{
  NOKOGIRI_DEBUG_START(schema);
  xmlSchemaFree(schema);
  NOKOGIRI_DEBUG_END(schema);
}

/*
 * call-seq:
 *  validate_document(document)
 *
 * Validate a Nokogiri::XML::Document against this Schema.
 */
static VALUE validate_document(VALUE self, VALUE document)
{
  xmlDocPtr doc;
  xmlSchemaPtr schema;

  Data_Get_Struct(self, xmlSchema, schema);
  Data_Get_Struct(document, xmlDoc, doc);

  VALUE errors = rb_ary_new();

  xmlSchemaValidCtxtPtr valid_ctxt = xmlSchemaNewValidCtxt(schema);

  if(NULL == valid_ctxt) {
    // we have a problem
    rb_raise(rb_eRuntimeError, "Could not create a validation context");
  }

#ifdef HAVE_XMLSCHEMASETVALIDSTRUCTUREDERRORS
  xmlSchemaSetValidStructuredErrors(
    valid_ctxt,
    Nokogiri_error_array_pusher,
    (void *)errors
  );
#endif

  xmlSchemaValidateDoc(valid_ctxt, doc);

  xmlSchemaFreeValidCtxt(valid_ctxt);

  return errors;
}

/*
 * call-seq:
 *  read_memory(string)
 *
 * Create a new Schema from the contents of +string+
 */
static VALUE read_memory(VALUE klass, VALUE content)
{

  xmlSchemaParserCtxtPtr ctx = xmlSchemaNewMemParserCtxt(
      (const char *)StringValuePtr(content),
      RSTRING_LEN(content)
  );

  VALUE errors = rb_ary_new();
  xmlSetStructuredErrorFunc((void *)errors, Nokogiri_error_array_pusher);

#ifdef HAVE_XMLSCHEMASETPARSERSTRUCTUREDERRORS
  xmlSchemaSetParserStructuredErrors(
    ctx,
    Nokogiri_error_array_pusher,
    (void *)errors
  );
#endif

  xmlSchemaPtr schema = xmlSchemaParse(ctx);

  xmlSetStructuredErrorFunc(NULL, NULL);
  xmlSchemaFreeParserCtxt(ctx);

  if(NULL == schema) {
    xmlErrorPtr error = xmlGetLastError();
    if(error)
      Nokogiri_error_raise(NULL, error);
    else
      rb_raise(rb_eRuntimeError, "Could not parse document");

    return Qnil;
  }

  VALUE rb_schema = Data_Wrap_Struct(klass, 0, dealloc, schema);
  rb_iv_set(rb_schema, "@errors", errors);

  return rb_schema;
}

/*
 * call-seq:
 *  from_document(doc)
 *
 * Create a new Schema from the Nokogiri::XML::Document +doc+
 */
static VALUE from_document(VALUE klass, VALUE document)
{
  xmlDocPtr doc;
  Data_Get_Struct(document, xmlDoc, doc);

  // In case someone passes us a node. ugh.
  doc = doc->doc;

  xmlSchemaParserCtxtPtr ctx = xmlSchemaNewDocParserCtxt(doc);

  VALUE errors = rb_ary_new();
  xmlSetStructuredErrorFunc((void *)errors, Nokogiri_error_array_pusher);

#ifdef HAVE_XMLSCHEMASETPARSERSTRUCTUREDERRORS
  xmlSchemaSetParserStructuredErrors(
    ctx,
    Nokogiri_error_array_pusher,
    (void *)errors
  );
#endif

  xmlSchemaPtr schema = xmlSchemaParse(ctx);

  xmlSetStructuredErrorFunc(NULL, NULL);
  xmlSchemaFreeParserCtxt(ctx);

  if(NULL == schema) {
    xmlErrorPtr error = xmlGetLastError();
    if(error)
      Nokogiri_error_raise(NULL, error);
    else
      rb_raise(rb_eRuntimeError, "Could not parse document");

    return Qnil;
  }

  VALUE rb_schema = Data_Wrap_Struct(klass, 0, dealloc, schema);
  rb_iv_set(rb_schema, "@errors", errors);

  return rb_schema;

  return Qnil;
}

VALUE cNokogiriXmlSchema;
void init_xml_schema()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE klass = rb_define_class_under(xml, "Schema", rb_cObject);

  cNokogiriXmlSchema = klass;

  rb_define_singleton_method(klass, "read_memory", read_memory, 1);
  rb_define_singleton_method(klass, "from_document", from_document, 1);
  rb_define_private_method(klass, "validate_document", validate_document, 1);
}
