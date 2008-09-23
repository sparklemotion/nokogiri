#include <xml_node.h>

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
 *  next_sibling
 *
 * Returns the next sibling node
 */
static VALUE next_sibling(VALUE self)
{
  xmlNodePtr node, sibling;
  Data_Get_Struct(self, xmlNode, node);

  sibling = node->next;
  if(!sibling) return Qnil;

  return Nokogiri_wrap_xml_node(sibling) ;
}

/*
 * call-seq:
 *  previous_sibling
 *
 * Returns the previous sibling node
 */
static VALUE previous_sibling(VALUE self)
{
  xmlNodePtr node, sibling;
  Data_Get_Struct(self, xmlNode, node);

  sibling = node->prev;
  if(!sibling) return Qnil;

  return Nokogiri_wrap_xml_node(sibling);
}

/*
 *  call-seq:
 *    replace(new_node)
 *
 *  replace node with the new node in the document.
 */
static VALUE replace(VALUE self, VALUE _new_node)
{
  xmlNodePtr node, new_node;
  Data_Get_Struct(self, xmlNode, node);
  Data_Get_Struct(_new_node, xmlNode, new_node);

  xmlReplaceNode(node, new_node);
  return self ;
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

  return Nokogiri_wrap_xml_node(child);
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

/*
 *  call-seq:
 *    remove(property)
 *
 *  remove the property +property+
 */
static VALUE remove_prop(VALUE self, VALUE property)
{
  xmlNodePtr node;
  xmlAttrPtr attr ;
  Data_Get_Struct(self, xmlNode, node);
  attr = xmlHasProp(node, (xmlChar *)StringValuePtr(property));
  if (attr) { xmlRemoveProp(attr); }
  return Qnil;
}

static VALUE get(VALUE self, VALUE attribute)
{
  xmlNodePtr node;
  xmlChar* propstr ;
  VALUE rval ;
  Data_Get_Struct(self, xmlNode, node);
  propstr = xmlGetProp(node, (xmlChar *)StringValuePtr(attribute));
  rval = rb_str_new2((char *)propstr) ;
  xmlFree(propstr);
  return rval ;
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
    xmlChar* propstr ;

    attr = rb_hash_new() ;
    Data_Get_Struct(self, xmlNode, node);

    prop = node->properties ;
    while (prop != NULL) {
        propstr = xmlGetProp(node, prop->name) ;
        rb_hash_aset(attr, rb_str_new2((const char*)prop->name),
                     rb_str_new2((char*)propstr));
        xmlFree(propstr);
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
  if(content) {
    VALUE rval = rb_str_new2((char *)content);
    xmlFree(content);
    return rval;
  }
  return Qnil;
}

/*
 * call-seq:
 *  parent=(parent_node)
 *
 * Set the parent Node for this Node
 */
static VALUE set_parent(VALUE self, VALUE parent_node)
{
  xmlNodePtr node, parent;
  Data_Get_Struct(self, xmlNode, node);
  Data_Get_Struct(parent_node, xmlNode, parent);

  xmlAddChild(parent, node);
  return parent_node;
}

/*
 * call-seq:
 *  parent
 *
 * Get the parent Node for this Node
 */
static VALUE get_parent(VALUE self)
{
  xmlNodePtr node, parent;
  Data_Get_Struct(self, xmlNode, node);

  parent = node->parent;
  if(!parent) return Qnil;

  return Nokogiri_wrap_xml_node(parent) ;
}

/*
 * call-seq:
 *  name=(new_name)
 *
 * Set the name for this Node
 */
static VALUE set_name(VALUE self, VALUE new_name)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);
  xmlNodeSetName(node, (xmlChar*)StringValuePtr(new_name));
  return new_name;
}

/*
 * call-seq:
 *  name
 *
 * Returns the name for this Node
 */
static VALUE get_name(VALUE self)
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
  xmlChar *path ;
  VALUE rval ;
  Data_Get_Struct(self, xmlNode, node);
  
  path = xmlGetNodePath(node);
  rval = rb_str_new2((char *)path);
  xmlFree(path);
  return rval ;
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

/*
 *  call-seq:
 *    add_next_sibling(node)
 *
 *  Insert +node+ after this node (as a sibling).
 */
static VALUE add_next_sibling(VALUE self, VALUE rb_node)
{
  xmlNodePtr node, new_sibling;
  Data_Get_Struct(self, xmlNode, node);
  Data_Get_Struct(rb_node, xmlNode, new_sibling);
  xmlAddNextSibling(node, new_sibling);

  rb_funcall(rb_node, rb_intern("decorate!"), 0);

  return rb_node;
}

/*
 *  call-seq:
 *    add_previous_sibling(node)
 *
 *  Insert +node+ before this node (as a sibling).
 */
static VALUE add_previous_sibling(VALUE self, VALUE rb_node)
{
  xmlNodePtr node, new_sibling;
  Data_Get_Struct(self, xmlNode, node);
  Data_Get_Struct(rb_node, xmlNode, new_sibling);
  xmlAddPrevSibling(node, new_sibling);

  rb_funcall(rb_node, rb_intern("decorate!"), 0);

  return rb_node;
}

static VALUE to_xml(VALUE self)
{
  xmlBufferPtr buf ;
  xmlNodePtr node ;
  VALUE xml ;

  Data_Get_Struct(self, xmlNode, node);

  buf = xmlBufferCreate() ;
  xmlNodeDump(buf, node->doc, node, 2, 1);
  xml = rb_str_new2((char*)buf->content);
  xmlBufferFree(buf);
  return xml ;
}


static VALUE new(int argc, VALUE *argv, VALUE klass)
{
  VALUE name, ns;
  xmlNsPtr xml_ns = NULL;

  rb_scan_args(argc, argv, "11", &name, &ns);

  if (RTEST(ns))
    Data_Get_Struct(ns, xmlNs, xml_ns);

  xmlNodePtr node = xmlNewNode(xml_ns, (xmlChar *)StringValuePtr(name));
  VALUE rb_node = Nokogiri_wrap_xml_node(node) ;

  if(rb_block_given_p()) rb_yield(rb_node);

  return rb_node;
}


static VALUE new_from_str(VALUE klass, VALUE xml)
{
    /*
     *  I couldn't find a more efficient way to do this. So we create a new
     *  document and copy (recursively) the root node.
     */
    VALUE rb_doc ;
    xmlDocPtr doc ;
    xmlNodePtr node ;

    rb_doc = rb_funcall(cNokogiriXmlDocument, rb_intern("read_memory"), 4,
                        xml, Qnil, Qnil, INT2NUM(0));
    Data_Get_Struct(rb_doc, xmlDoc, doc);
    node = xmlCopyNode(xmlDocGetRootElement(doc), 1); /* 1 => recursive */
    return Nokogiri_wrap_xml_node(node);
}

static void gc_mark_node(xmlNodePtr node)
{
  if (node->doc && node->doc->_private)
    rb_gc_mark((VALUE)node->doc->_private);
}

VALUE Nokogiri_wrap_xml_node(xmlNodePtr node)
{
  if (node->_private)
    return (VALUE)node->_private ;
  VALUE rb_node = Data_Wrap_Struct(cNokogiriXmlNode, gc_mark_node, NULL, node) ;
  node->_private = (void*)rb_node ;
  rb_funcall(rb_node, rb_intern("decorate!"), 0);
  return rb_node ;
}

VALUE cNokogiriXmlNode ;
void init_xml_node()
{
  VALUE klass = cNokogiriXmlNode = rb_const_get(mNokogiriXml, rb_intern("Node"));

  rb_define_singleton_method(klass, "new", new, -1);
  rb_define_singleton_method(klass, "new_from_str", new_from_str, 1);

  rb_define_method(klass, "document", document, 0);
  rb_define_method(klass, "name", get_name, 0);
  rb_define_method(klass, "name=", set_name, 1);
  rb_define_method(klass, "parent=", set_parent, 1);
  rb_define_method(klass, "parent", get_parent, 0);
  rb_define_method(klass, "child", child, 0);
  rb_define_method(klass, "next_sibling", next_sibling, 0);
  rb_define_method(klass, "previous_sibling", previous_sibling, 0);
  rb_define_method(klass, "replace", replace, 1);
  rb_define_method(klass, "type", type, 0);
  rb_define_method(klass, "content", get_content, 0);
  rb_define_method(klass, "content=", set_content, 1);
  rb_define_method(klass, "path", path, 0);
  rb_define_method(klass, "key?", key_eh, 1);
  rb_define_method(klass, "blank?", blank_eh, 0);
  rb_define_method(klass, "[]=", set, 2);
  rb_define_method(klass, "remove", remove_prop, 1);
  rb_define_method(klass, "attributes", attributes, 0);
  rb_define_method(klass, "add_previous_sibling", add_previous_sibling, 1);
  rb_define_method(klass, "add_next_sibling", add_next_sibling, 1);
  rb_define_method(klass, "to_xml", to_xml, 0);

  rb_define_private_method(klass, "get", get, 1);
}
