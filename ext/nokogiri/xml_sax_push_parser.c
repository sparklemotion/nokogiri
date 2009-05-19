#include <xml_sax_push_parser.h>

static void deallocate(xmlParserCtxtPtr ctx)
{
  NOKOGIRI_DEBUG_START(ctx);
  if(ctx != NULL) xmlFreeParserCtxt(ctx);
  NOKOGIRI_DEBUG_END(ctx);
}

static VALUE allocate(VALUE klass)
{
  return Data_Wrap_Struct(klass, NULL, deallocate, NULL);
}

/*
 * call-seq:
 *  native_write(chunk, last_chunk)
 *
 * Write +chunk+ to PushParser. +last_chunk+ triggers the end_document handle
 */
static VALUE native_write(VALUE self, VALUE _chunk, VALUE _last_chunk)
{
  xmlParserCtxtPtr ctx;
  Data_Get_Struct(self, xmlParserCtxt, ctx);

  const char * chunk  = NULL;
  int last_chunk      = 0;
  int size            = 0;

  if(Qnil != _chunk) {
    chunk = StringValuePtr(_chunk);
    size = RSTRING_LEN(_chunk);
  }
  if(Qtrue == _last_chunk) last_chunk = 1;

  if(xmlParseChunk(ctx, chunk, size, last_chunk))
    rb_raise(rb_eRuntimeError, "Couldn't parse chunk");

  return self;
}

/*
 * call-seq:
 *  initialize_native(xml_sax, filename)
 *
 * Initialize the push parser with +xml_sax+ using +filename+
 */
static VALUE initialize_native(VALUE self, VALUE _xml_sax, VALUE _filename)
{
  xmlSAXHandlerPtr sax;

  Data_Get_Struct(_xml_sax, xmlSAXHandler, sax);
  
  const char * filename = NULL;

  if(_filename != Qnil) filename = StringValuePtr(_filename);

  xmlParserCtxtPtr ctx = xmlCreatePushParserCtxt(
      sax,
      (void *)self,
      NULL,
      0,
      filename
  );
  if(ctx == NULL)
    rb_raise(rb_eRuntimeError, "Could not create a parser context");

  ctx->sax2 = 1;
  DATA_PTR(self) = ctx;
  return self;
}

VALUE cNokogiriXmlSaxPushParser ;
void init_xml_sax_push_parser()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE sax = rb_define_module_under(xml, "SAX");
  VALUE klass = rb_define_class_under(sax, "PushParser", rb_cObject);

  cNokogiriXmlSaxPushParser = klass;

  rb_define_alloc_func(klass, allocate);
  rb_define_private_method(klass, "initialize_native", initialize_native, 2);
  rb_define_private_method(klass, "native_write", native_write, 2);
}
