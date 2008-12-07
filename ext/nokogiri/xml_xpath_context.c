#include <xml_xpath_context.h>

static void deallocate(xmlXPathContextPtr ctx)
{
  NOKOGIRI_DEBUG_START(ctx);
  xmlXPathFreeContext(ctx);
  NOKOGIRI_DEBUG_END(ctx);
}

/*
 * call-seq:
 *  register_ns(prefix, uri)
 *
 * Register the namespace with +prefix+ and +uri+.
 */
static VALUE register_ns(VALUE self, VALUE prefix, VALUE uri)
{
  xmlXPathContextPtr ctx;
  Data_Get_Struct(self, xmlXPathContext, ctx);

  xmlXPathRegisterNs( ctx,
                      (const xmlChar *)StringValuePtr(prefix),
                      (const xmlChar *)StringValuePtr(uri)
  );
  return self;
}

static void ruby_funcall(xmlXPathParserContextPtr ctx, int nargs)
{
  VALUE xpath_handler = Qnil;
  VALUE node_set = Qnil;
  xmlXPathObjectPtr obj;

  assert(ctx);
  assert(ctx->context);
  assert(ctx->context->userData);

  xpath_handler = (VALUE)(ctx->context->userData);

  VALUE * argv = (VALUE *)calloc((unsigned int)nargs, sizeof(VALUE));

  int i = 0;
  for(i = 0; i < nargs; i++) {
    obj = valuePop(ctx);
    switch(obj->type) {
      case XPATH_STRING:
        argv[i] = rb_str_new2((char *)obj->stringval);
      default:
        argv[i] = rb_str_new2((char *)xmlXPathCastToString(obj));
    }
  }

  rb_funcall2(xpath_handler,
              rb_intern((const char *)ctx->context->function),
              nargs,
              argv
  );

  free(argv);
}

static xmlXPathFunction lookup( void *ctx,
                                const xmlChar * name,
                                const xmlChar* ns_uri )
{
  VALUE xpath_handler = (VALUE)ctx;
  if(rb_respond_to(xpath_handler, rb_intern((const char *)name)))
    return ruby_funcall;

  return NULL;
}

/*
 * call-seq:
 *  evaluate(search_path)
 *
 * Evaluate the +search_path+ returning an XML::XPath object.
 */
static VALUE evaluate(int argc, VALUE *argv, VALUE self)
{
  VALUE search_path, xpath_handler;
  xmlXPathContextPtr ctx;
  Data_Get_Struct(self, xmlXPathContext, ctx);

  if(rb_scan_args(argc, argv, "11", &search_path, &xpath_handler) == 1)
    xpath_handler = Qnil;

  xmlChar* query = (xmlChar *)StringValuePtr(search_path);

  if(Qnil != xpath_handler) {
    // FIXME: not sure if this is the correct place to shove private data.
    ctx->userData = (void *)xpath_handler;
    xmlXPathRegisterFuncLookup(ctx, lookup, (void *)xpath_handler);
  }

  xmlXPathObjectPtr xpath = xmlXPathEvalExpression(query, ctx);
  if(xpath == NULL) {
    VALUE xpath = rb_const_get(mNokogiriXml, rb_intern("XPath"));
    VALUE error = rb_const_get(xpath, rb_intern("SyntaxError"));
    rb_raise(error, "Couldn't evaluate expression '%s'", query);
  }

  VALUE xpath_object = Nokogiri_wrap_xml_xpath(xpath);

  assert(ctx->node);
  assert(ctx->node->doc);
  assert(ctx->node->doc->_private);

  rb_funcall( xpath_object,
              rb_intern("document="),
              1,
              (VALUE)ctx->node->doc->_private
            );
  return xpath_object;
}

/*
 * call-seq:
 *  new(node)
 *
 * Create a new XPathContext with +node+ as the reference point.
 */
static VALUE new(VALUE klass, VALUE nodeobj)
{
  xmlXPathInit();

  xmlNodePtr node ;
  Data_Get_Struct(nodeobj, xmlNode, node);

  xmlXPathContextPtr ctx = xmlXPathNewContext(node->doc);
  ctx->node = node;
  VALUE self = Data_Wrap_Struct(klass, 0, deallocate, ctx);
  //rb_iv_set(self, "@xpath_handler", Qnil);
  return self;
}

VALUE cNokogiriXmlXpathContext;
void init_xml_xpath_context(void)
{
  VALUE module = rb_define_module("Nokogiri");

  /*
   * Nokogiri::XML
   */
  VALUE xml = rb_define_module_under(module, "XML");

  /*
   * XPathContext is the entry point for searching a Document by using XPath.
   */
  VALUE klass = rb_define_class_under(xml, "XPathContext", rb_cObject);

  cNokogiriXmlXpathContext = klass;

  rb_define_singleton_method(klass, "new", new, 1);
  rb_define_method(klass, "evaluate", evaluate, -1);
  rb_define_method(klass, "register_ns", register_ns, 2);
}
