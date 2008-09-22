#include <xml_xpath.h>

static void free_xpath_object(xmlXPathObjectPtr xpath)
{
    xmlXPathFreeNodeSetList(xpath); // despite the name, this frees the xpath but not the contained node set
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
      return Nokogiri_wrap_xml_node_set(xpath->nodesetval);
  else
      return Nokogiri_wrap_xml_node_set(xmlXPathNodeSetCreate(NULL));
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
  VALUE self = Data_Wrap_Struct(klass, NULL, free_xpath_object, xpath);
  xmlXPathFreeContext(ctx);

  return self;
}

VALUE cNokogiriXmlXpath ;
void init_xml_xpath(void)
{
  VALUE klass = cNokogiriXmlXpath = rb_eval_string("Nokogiri::XML::XPath");
  rb_define_singleton_method(klass, "new", new, 2);
  rb_define_method(klass, "node_set", node_set, 0);
}
