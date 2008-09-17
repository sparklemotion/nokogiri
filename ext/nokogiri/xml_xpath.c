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

  if (xpath->nodesetval)
      return Data_Wrap_Struct(cNokogiriXmlNodeSet, NULL, NULL, xpath->nodesetval);
  else
      return Data_Wrap_Struct(cNokogiriXmlNodeSet, NULL, NULL, xmlXPathNodeSetCreate(NULL));
}

static VALUE new(VALUE klass, VALUE nodeobj, VALUE search_path)
{
  xmlXPathInit();

  xmlNodePtr node ;
  Data_Get_Struct(nodeobj, xmlNode, node);

  xmlXPathContextPtr ctx = xmlXPathNewContext(node->doc);
  ctx->node = node ;
  xmlChar* query = (xmlChar *)StringValuePtr(search_path) ;
  xmlXPathObjectPtr xpath = xmlXPathEvalExpression(query, ctx );
  if(xpath == NULL) {
    xmlXPathFreeContext(ctx);
    rb_raise(rb_eRuntimeError, "Couldn't evaluate expression '%s'", query);
  }

  // FIXME: GC
  VALUE self = Data_Wrap_Struct(klass, NULL, NULL, xpath);
  VALUE rb_ctx = Data_Wrap_Struct(rb_cObject, NULL, free_context, ctx);
  rb_iv_set(self, "@context", rb_ctx);

  return self;
}

VALUE cNokogiriXmlXpath ;
void init_xml_xpath(void)
{
  VALUE klass = cNokogiriXmlXpath = rb_eval_string("Nokogiri::XML::XPath");
  rb_define_singleton_method(klass, "new", new, 2);
  rb_define_method(klass, "node_set", node_set, 0);
}
