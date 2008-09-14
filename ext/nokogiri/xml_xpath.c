#include <xml_xpath.h>

static void free_context(xmlXPathContextPtr ctx)
{
  xmlXPathFreeContext(ctx);
}

/*
 * call-seq:
 *  node_set
 *
 * Fetch the node set associated with this xpath context.
 */
static VALUE node_set(VALUE self)
{
  xmlXPathObjectPtr xpath;
  Data_Get_Struct(self, xmlXPathObject, xpath);

  VALUE klass = rb_eval_string("Nokogiri::XML::NodeSet");
  return Data_Wrap_Struct(klass, NULL, NULL, xpath->nodesetval);
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
  if(xpath == NULL) {
    xmlXPathFreeContext(ctx);
    rb_raise(rb_eRuntimeError, "Couldn't evaluate expression");
  }

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
  rb_define_method(klass, "node_set", node_set, 0);
}
