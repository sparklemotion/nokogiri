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

/*
 * call-seq:
 *  evaluate(search_path)
 *
 * Evaluate the +search_path+ returning an XML::XPath object.
 */
static VALUE evaluate(VALUE self, VALUE search_path)
{
  xmlXPathContextPtr ctx;
  Data_Get_Struct(self, xmlXPathContext, ctx);

  xmlChar* query = (xmlChar *)StringValuePtr(search_path);
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
  ctx->node = node ;
  return Data_Wrap_Struct(klass, 0, deallocate, ctx);
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
  rb_define_method(klass, "evaluate", evaluate, 1);
  rb_define_method(klass, "register_ns", register_ns, 2);
}
