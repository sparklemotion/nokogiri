#include <xml_attr.h>

/*
 * call-seq:
 *  value=(content)
 *
 * Set the value for this Attr to +content+
 */
static VALUE set_value(VALUE self, VALUE content)
{
  xmlAttrPtr attr;
  Data_Get_Struct(self, xmlAttr, attr);

  if(attr->children) xmlFreeNodeList(attr->children);

  attr->children = attr->last = NULL;

  if(content) {
    xmlChar *buffer;
    xmlNode *tmp;

    // Encode our content
    buffer = xmlEncodeEntitiesReentrant(attr->doc, (unsigned char *)StringValuePtr(content));

    attr->children = xmlStringGetNodeList(attr->doc, buffer);
    attr->last = NULL;
    tmp = attr->children;

    // Loop through the children
    for(tmp = attr->children; tmp; tmp = tmp->next) {
      tmp->parent = (xmlNode *)attr;
      tmp->doc = attr->doc;
      if(tmp->next == NULL) attr->last = tmp;
    }

    // Free up memory
    xmlFree(buffer);
  }

  return content;
}

/*
 * call-seq:
 *  new(document, content)
 *
 * Create a new Attr element on the +document+ with +name+
 */
static VALUE new(VALUE klass, VALUE doc, VALUE name)
{
  xmlDocPtr xml_doc;
  Data_Get_Struct(doc, xmlDoc, xml_doc);

  xmlAttrPtr node = xmlNewDocProp(
      xml_doc,
      (const xmlChar *)StringValuePtr(name),
      NULL
  );

  VALUE rb_node = Nokogiri_wrap_xml_node((xmlNodePtr)node);

  if(rb_block_given_p()) rb_yield(rb_node);

  return rb_node;
}

VALUE cNokogiriXmlAttr;
void init_xml_attr()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE node = rb_define_class_under(xml, "Node", rb_cObject);

  /*
   * Attr represents a Attr node in an xml document.
   */
  VALUE klass = rb_define_class_under(xml, "Attr", node);

  cNokogiriXmlAttr = klass;

  rb_define_singleton_method(klass, "new", new, 2);
  rb_define_method(klass, "value=", set_value, 1);
}
