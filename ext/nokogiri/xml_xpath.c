#include <xml_xpath.h>

static void deallocate(xmlXPathObjectPtr xpath)
{
  xmlXPathFreeNodeSetList(xpath); // despite the name, this frees the xpath but not the contained node set
}

VALUE Nokogiri_wrap_xml_xpath(xmlXPathObjectPtr xpath)
{
  return Data_Wrap_Struct(cNokogiriXmlXpath, 0, deallocate, xpath);
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

  return Nokogiri_wrap_xml_node_set(xmlXPathNodeSetCreate(NULL));
}

VALUE cNokogiriXmlXpath;
void init_xml_xpath(void)
{
  VALUE module = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(module, "XML");
  VALUE klass = rb_define_class_under(xml, "XPath", rb_cObject);

  cNokogiriXmlXpath = klass;
  rb_define_method(klass, "node_set", node_set, 0);
}
