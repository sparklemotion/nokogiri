#include <nokogiri.h>

VALUE cNokogiriHtml4SaxParserContext ;

static VALUE
noko_html4_sax_parser_s_parse_memory(VALUE klass, VALUE data, VALUE encoding)
{
  htmlParserCtxtPtr ctxt;

  Check_Type(data, T_STRING);

  if (!(int)RSTRING_LEN(data)) {
    rb_raise(rb_eRuntimeError, "input string cannot be empty");
  }

  ctxt = htmlCreateMemoryParserCtxt(StringValuePtr(data),
                                    (int)RSTRING_LEN(data));
  if (ctxt->sax) {
    xmlFree(ctxt->sax);
    ctxt->sax = NULL;
  }

  if (RTEST(encoding)) {
    xmlCharEncodingHandlerPtr enc = xmlFindCharEncodingHandler(StringValueCStr(encoding));
    if (enc != NULL) {
      xmlSwitchToEncoding(ctxt, enc);
      if (ctxt->errNo == XML_ERR_UNSUPPORTED_ENCODING) {
        rb_raise(rb_eRuntimeError, "Unsupported encoding %s",
                 StringValueCStr(encoding));
      }
    }
  }

  return noko_xml_sax_parser_context_wrap(klass, ctxt);
}

static VALUE
noko_html4_sax_parser_context_s_parse_file(VALUE klass, VALUE filename, VALUE encoding)
{
  htmlParserCtxtPtr ctxt = htmlCreateFileParserCtxt(
                             StringValueCStr(filename),
                             StringValueCStr(encoding)
                           );

  if (ctxt->sax) {
    xmlFree(ctxt->sax);
    ctxt->sax = NULL;
  }

  return noko_xml_sax_parser_context_wrap(klass, ctxt);
}

static VALUE
noko_html4_sax_parser_context__parse_with(VALUE rb_context, VALUE rb_sax_parser)
{
  htmlParserCtxtPtr ctxt;
  htmlSAXHandlerPtr sax;

  if (!rb_obj_is_kind_of(rb_sax_parser, cNokogiriXmlSaxParser)) {
    rb_raise(rb_eArgError, "argument must be a Nokogiri::XML::SAX::Parser");
  }

  ctxt = noko_xml_sax_parser_context_unwrap(rb_context);
  sax = noko_xml_sax_parser_unwrap(rb_sax_parser);

  ctxt->sax = sax;
  ctxt->userData = ctxt; /* so we can use libxml2/SAX2.c handlers if we want to */
  ctxt->_private = (void *)rb_sax_parser;

  xmlSetStructuredErrorFunc(NULL, NULL);

  /* although we're calling back into Ruby here, we don't need to worry about exceptions, because we
   * don't have any cleanup to do. The only memory we need to free is handled by
   * xml_sax_parser_context_type_free */
  htmlParseDocument(ctxt);

  return Qnil;
}

void
noko_init_html_sax_parser_context(void)
{
  assert(cNokogiriXmlSaxParserContext);
  cNokogiriHtml4SaxParserContext = rb_define_class_under(mNokogiriHtml4Sax, "ParserContext",
                                   cNokogiriXmlSaxParserContext);

  rb_define_singleton_method(cNokogiriHtml4SaxParserContext, "memory",
                             noko_html4_sax_parser_s_parse_memory, 2);
  rb_define_singleton_method(cNokogiriHtml4SaxParserContext, "file",
                             noko_html4_sax_parser_context_s_parse_file, 2);

  rb_define_method(cNokogiriHtml4SaxParserContext, "parse_with",
                   noko_html4_sax_parser_context__parse_with, 1);
}
