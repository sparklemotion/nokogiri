#include <xml_xpath.h>

static free_context(xmlXPathContextPtr ctx)
{
  xmlXPathFreeContext(ctx);
}

/*
 * call-seq:
 *  evaluate(search_path)
 *
 * Evaluate +search_path+
 */
static VALUE evaluate(VALUE self, VALUE search_path)
{
  xmlXPathContextPtr xpath_ctx;

  VALUE context = rb_iv_get(self, "@context");
  Data_Get_Struct(context, xmlXPathContext, xpath_ctx);
  xmlXPathObjectPtr xpath_obj = xmlXPathEvalExpression(
      (xmlChar *)StringValuePtr(search_path),
      xpath_ctx
  );
}

static VALUE new(VALUE klass, VALUE document, VALUE search_path)
{
  xmlXPathInit();

  xmlDocPtr doc;
  Data_Get_Struct(document, xmlDoc, doc);

  xmlXPathContextPtr ctx = xmlXPathNewContext(doc);
  xmlXPathObjectPtr xpath = xmlXPathEvalExpression(
      (xmlChar *)StringValuePtr(search_path),
      ctx
  );

  // FIXME: GC
  VALUE self = Data_Wrap_Struct(klass, NULL, NULL, xpath);
  VALUE rb_ctx = Data_Wrap_Struct(rb_cObject, NULL, free_context, ctx);
  rb_iv_set(self, "@context", rb_ctx);

  return self;
}

void init_xml_xpath(void)
{
  VALUE klass = rb_eval_string("Nokogiri::XML::XPath");
  rb_define_singleton_method(klass, "new", new, 2);
}
