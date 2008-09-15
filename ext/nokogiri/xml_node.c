#include <xml_node.h>

VALUE Nokogiri_wrap_xml_node(xmlNodePtr root)
{
  VALUE klass = rb_eval_string("Nokogiri::XML::Node");
  VALUE node = Data_Wrap_Struct(klass, NULL, NULL, root);
  root->_private = (void *)node;
  return node;
}

/*
 * call-seq:
 *  blank?
 *
 * Is this node blank?
 */
static VALUE blank_eh(VALUE self)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);
  if(1 == xmlIsBlankNode(node))
    return Qtrue;
  return Qfalse;
}

/*
 * call-seq:
 *  next
 *
 * Returns the next sibling node
 */
static VALUE next(VALUE self)
{
  xmlNodePtr node, sibling;
  Data_Get_Struct(self, xmlNode, node);

  sibling = node->next;
  if(!sibling) return Qnil;

  if(sibling->_private)
    return (VALUE)sibling->_private;

  VALUE klass = rb_eval_string("Nokogiri::XML::Node");
  // FIXME: Do we need to GC?
  VALUE rb_next = Data_Wrap_Struct(klass, NULL, NULL, sibling);
  sibling->_private = (void *)rb_next;
  return rb_next;
}

/*
 * call-seq:
 *  child
 *
 * Returns the child node
 */
static VALUE child(VALUE self)
{
  xmlNodePtr node, child;
  Data_Get_Struct(self, xmlNode, node);

  child = node->children;
  if(!child) return Qnil;

  if(child->_private)
    return (VALUE)child->_private;

  VALUE klass = rb_eval_string("Nokogiri::XML::Node");
  // FIXME: Do we need to GC?
  VALUE rb_child = Data_Wrap_Struct(klass, NULL, NULL, child);
  child->_private = (void *)rb_child;
  return rb_child;
}

/*
 * call-seq:
 *  key?(attribute)
 *
 * Returns true if +attribute+ is set
 */
static VALUE key_eh(VALUE self, VALUE attribute)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);
  if(xmlHasProp(node, (xmlChar *)StringValuePtr(attribute)))
    return Qtrue;
  return Qfalse;
}

/*
 * call-seq:
 *  []=(property, value)
 *
 * Set the +property+ to +value+
 */
static VALUE set(VALUE self, VALUE property, VALUE value)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);
  xmlSetProp(node, (xmlChar *)StringValuePtr(property),
      (xmlChar *)StringValuePtr(value));

  return value;
}

static VALUE get(VALUE self, VALUE attribute)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);
  return rb_str_new2((char *)xmlGetProp(node, (xmlChar *)StringValuePtr(attribute)));
}

/*
 *  call-seq
 *    attributes()
 *
 *  returns a hash containing the node's attributes.
 */
static VALUE attributes(VALUE self)
{
    /* this code in the mod eof xmlHasProp() */
    xmlNodePtr node ;
    xmlAttrPtr prop;
    VALUE attr ;

    attr = rb_hash_new() ;
    Data_Get_Struct(self, xmlNode, node);

    prop = node->properties ;
    while (prop != NULL) {
        rb_hash_aset(attr, rb_str_new2((const char*)prop->name),
                     rb_str_new2((char*)xmlGetProp(node, prop->name)));
        prop = prop->next ;
    }
    return attr ;
}

/*
 * call-seq:
 *  type
 *
 * Get the type for this node
 */
static VALUE type(VALUE self)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);
  return INT2NUM((int)node->type);
}

/*
 * call-seq:
 *  content=
 *
 * Set the content for this Node
 */
static VALUE set_content(VALUE self, VALUE content)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);
  xmlNodeSetContent(node, (xmlChar *)StringValuePtr(content));
  return content;
}

/*
 * call-seq:
 *  content
 *
 * Returns the content for this Node
 */
static VALUE get_content(VALUE self)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);

  xmlChar * content = xmlNodeGetContent(node);
  if(content)
    return rb_str_new2((char *)content);

  return Qnil;
}

/*
 * call-seq:
 *  name
 *
 * Returns the name for this Node
 */
static VALUE name(VALUE self)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);
  return rb_str_new2((const char *)node->name);
}

/*
 * call-seq:
 *  path
 *
 * Returns the path associated with this Node
 */
static VALUE path(VALUE self)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);
  return rb_str_new2((char *)xmlGetNodePath(node));
}

/*
 * call-seq:
 *  document
 *
 * Returns the Nokogiri::XML::Document associated with this Node
 */
static VALUE document(VALUE self)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);

  if(!node->doc) return Qnil;
  return (VALUE)node->doc->_private;
}

static VALUE new(int argc, VALUE *argv, VALUE klass)
{
  VALUE name;
  VALUE ns;
  xmlNsPtr xml_ns = NULL;

  rb_scan_args(argc, argv, "11", &name, &ns);

  if (RTEST(ns))
    Data_Get_Struct(ns, xmlNs, xml_ns);

  xmlNodePtr node = xmlNewNode(xml_ns, (xmlChar *)StringValuePtr(name));
  VALUE rb_node = Data_Wrap_Struct(klass, NULL, NULL, node);
  node->_private = (void *)rb_node;
  return rb_node;
}

void init_xml_node()
{
  VALUE m_nokogiri  = rb_const_get(rb_cObject, rb_intern("Nokogiri"));
  VALUE m_xml       = rb_const_get(m_nokogiri, rb_intern("XML"));
  VALUE klass       = rb_const_get(m_xml, rb_intern("Node"));

  rb_define_singleton_method(klass, "new", new, -1);
  rb_define_method(klass, "document", document, 0);
  rb_define_method(klass, "name", name, 0);
  rb_define_method(klass, "child", child, 0);
  rb_define_method(klass, "next", next, 0);
  rb_define_method(klass, "type", type, 0);
  rb_define_method(klass, "content", get_content, 0);
  rb_define_method(klass, "content=", set_content, 1);
  rb_define_method(klass, "path", path, 0);
  rb_define_method(klass, "key?", key_eh, 1);
  rb_define_method(klass, "blank?", blank_eh, 0);
  rb_define_method(klass, "[]=", set, 2);
  rb_define_method(klass, "attributes", attributes, 0);

  rb_define_private_method(klass, "get", get, 1);
}
