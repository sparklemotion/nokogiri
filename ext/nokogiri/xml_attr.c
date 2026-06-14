#include <nokogiri.h>

VALUE cNokogiriXmlAttr;

/*
 * call-seq:
 *  value=(content)
 *
 * Set the value for this Attr to +content+. Use +nil+ to remove the value
 * (e.g., a HTML boolean attribute).
 */
static VALUE
noko_xml_attr_set_value(VALUE self, VALUE content)
{
  xmlAttrPtr attr;

  Noko_Node_Get_Struct(self, xmlAttr, attr);

  {
    /* Unlink and pin any wrapped children */
    xmlNode *cur = attr->children;
    xmlNode *next;

    while (cur) {
      next = cur->next;
      if (cur->_private) {
        xmlUnlinkNode(cur);
        noko_xml_document_pin_node(cur);
      }
      cur = next;
    }
  }

  if (content == Qnil) {
    xmlNodeSetContent((xmlNodePtr)attr, NULL); /* Clear any remaining unwrapped children. */
  } else {
    xmlChar *value = xmlEncodeEntitiesReentrant(attr->doc, (unsigned char *)StringValueCStr(content));

    if (xmlStrlen(value) == 0) {
      xmlNodeSetContent((xmlNodePtr)attr, NULL); /* Clear any remaining unwrapped children. */

      /* Preserve empty-string attributes as `foo=""` and not boolean `foo` */
      attr->children = attr->last = xmlNewDocText(attr->doc, value);
      attr->children->parent = (xmlNode *)attr;
    } else {
      xmlNodeSetContent((xmlNodePtr)attr, value);
    }
    xmlFree(value);
  }

  return content;
}

/*
 * call-seq:
 *  new(document, name)
 *
 * Create a new Attr element on the +document+ with +name+
 */
static VALUE
noko_xml_attr__new(int argc, VALUE *argv, VALUE klass)
{
  xmlDocPtr xml_doc;
  VALUE document;
  VALUE name;
  VALUE rest;
  xmlAttrPtr node;
  VALUE rb_node;

  rb_scan_args(argc, argv, "2*", &document, &name, &rest);

  if (! rb_obj_is_kind_of(document, cNokogiriXmlDocument)) {
    rb_raise(rb_eArgError, "parameter must be a Nokogiri::XML::Document");
  }

  xml_doc = noko_xml_document_unwrap(document);

  node = xmlNewDocProp(
           xml_doc,
           (const xmlChar *)StringValueCStr(name),
           NULL
         );

  noko_xml_document_pin_node((xmlNodePtr)node);

  rb_node = noko_xml_node_wrap(klass, (xmlNodePtr)node);
  rb_obj_call_init(rb_node, argc, argv);

  if (rb_block_given_p()) {
    rb_yield(rb_node);
  }

  return rb_node;
}

void
noko_init_xml_attr(void)
{
  assert(cNokogiriXmlNode);
  /*
   * Attr represents a Attr node in an xml document.
   */
  cNokogiriXmlAttr = rb_define_class_under(mNokogiriXml, "Attr", cNokogiriXmlNode);

  rb_define_singleton_method(cNokogiriXmlAttr, "new", noko_xml_attr__new, -1);

  rb_define_method(cNokogiriXmlAttr, "value=", noko_xml_attr_set_value, 1);
}
