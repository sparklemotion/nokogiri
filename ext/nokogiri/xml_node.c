#include <xml_node.h>

#ifdef DEBUG
static void debug_node_dealloc(xmlNodePtr x)
{
  NOKOGIRI_DEBUG_START(x)
  NOKOGIRI_DEBUG_END(x)
}
#else
#  define debug_node_dealloc 0
#endif

/*
 * call-seq:
 *  pointer_id
 *
 * Get the internal pointer number
 */
static VALUE pointer_id(VALUE self)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);

  return INT2NUM((int)(node));
}

/*
 * call-seq:
 *  encode_special_chars(string)
 *
 * Encode any special characters in +string+
 */
static VALUE encode_special_chars(VALUE self, VALUE string)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);
  xmlChar * encoded = xmlEncodeSpecialChars(
      node->doc,
      (const xmlChar *)StringValuePtr(string)
  );

  VALUE encoded_str = rb_str_new2((const char *)encoded);
  xmlFree(encoded);

  return encoded_str;
}

/*
 * call-seq:
 *  internal_subset
 *
 * Get the internal subset
 */
static VALUE internal_subset(VALUE self)
{
  xmlNodePtr node;
  xmlDocPtr doc;
  Data_Get_Struct(self, xmlNode, node);

  if(!node->doc) return Qnil;

  doc = node->doc;

  if(!doc->intSubset) return Qnil;

  return Nokogiri_wrap_xml_node((xmlNodePtr)doc->intSubset);
}

/*
 * call-seq:
 *  dup
 *
 * Copy this node
 */
static VALUE duplicate_node(VALUE self)
{
  xmlNodePtr node, dup;
  Data_Get_Struct(self, xmlNode, node);

  dup = xmlCopyNode(node, 1);
  if(dup == NULL) return Qnil;
  dup->doc = node->doc;
  assert(node->parent);

  xmlAddChild(node->parent, dup);

  return Nokogiri_wrap_xml_node(dup);
}

/*
 * call-seq:
 *  unlink
 *
 * Unlink this node from its current context.
 */
static VALUE unlink_node(VALUE self)
{
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, node);
  xmlUnlinkNode(node);
  return self;
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
 *    remove_attribute(property)
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

/*
 * call-seq:
 *   get(attribute)
 *
 * Get the value for +attribute+
 */
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
 *  call-seq:
 *    attributes()
 *
 *  returns a hash containing the node's attributes.
 */
static VALUE attributes(VALUE self)
{
    /* this code in the mode of xmlHasProp() */
    xmlNodePtr node ;
    VALUE attr ;

    attr = rb_hash_new() ;
    Data_Get_Struct(self, xmlNode, node);

    Nokogiri_xml_node_properties(node, attr);

    return attr ;
}

/*
 *  call-seq:
 *    namespaces()
 *
 *  returns a hash containing the node's namespaces.
 */
static VALUE namespaces(VALUE self)
{
    /* this code in the mode of xmlHasProp() */
    xmlNodePtr node ;
    VALUE attr ;

    attr = rb_hash_new() ;
    Data_Get_Struct(self, xmlNode, node);

    Nokogiri_xml_node_namespaces(node, attr);

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
  if(node->name) return rb_str_new2((const char *)node->name);
  return Qnil;
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
 * call-seq:
 *  add_previous_sibling(node)
 *
 * Insert +node+ before this node (as a sibling).
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

/*
 * call-seq:
 *  to_xml
 *
 * Returns this node as XML
 */
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


/*
 * call-seq:
 *   new(name)
 *
 * Create a new node with +name+
 */
static VALUE new(VALUE klass, VALUE name, VALUE document)
{
  xmlDocPtr doc;

  Data_Get_Struct(document, xmlDoc, doc);

  xmlNodePtr node = xmlNewNode(NULL, (xmlChar *)StringValuePtr(name));
  node->doc = doc;

  VALUE rb_node = Nokogiri_wrap_xml_node(node);

  if(rb_block_given_p()) rb_yield(rb_node);

  return rb_node;
}


/*
 * call-seq:
 *   new_from_str(string)
 *
 * Create a new node by parsing +string+
 */
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
    node->doc = doc;

    return Nokogiri_wrap_xml_node(node);
}

VALUE Nokogiri_wrap_xml_node(xmlNodePtr node)
{
  assert(node);
  assert(node->doc);
  assert(node->doc->_private);

  VALUE index = INT2NUM((int)node);
  VALUE document = (VALUE)node->doc->_private;

  VALUE node_cache = rb_funcall(document, rb_intern("node_cache"), 0);
  VALUE rb_node = rb_hash_aref(node_cache, index);

  if(rb_node != Qnil) return rb_node;

  switch(node->type)
  {
    VALUE klass;

    case XML_TEXT_NODE:
      klass = rb_const_get(mNokogiriXml, rb_intern("Text"));
      rb_node = Data_Wrap_Struct(klass, 0, debug_node_dealloc, node) ;
      break;
    case XML_COMMENT_NODE:
      klass = cNokogiriXmlComment;
      rb_node = Data_Wrap_Struct(klass, 0, debug_node_dealloc, node) ;
      break;
    case XML_ELEMENT_NODE:
      klass = rb_const_get(mNokogiriXml, rb_intern("Element"));
      rb_node = Data_Wrap_Struct(klass, 0, debug_node_dealloc, node) ;
      break;
    case XML_ENTITY_DECL:
      klass = rb_const_get(mNokogiriXml, rb_intern("EntityDeclaration"));
      rb_node = Data_Wrap_Struct(klass, 0, debug_node_dealloc, node) ;
      break;
    case XML_CDATA_SECTION_NODE:
      klass = cNokogiriXmlCData;
      rb_node = Data_Wrap_Struct(klass, 0, debug_node_dealloc, node) ;
      break;
    case XML_DTD_NODE:
      klass = rb_const_get(mNokogiriXml, rb_intern("DTD"));
      rb_node = Data_Wrap_Struct(klass, 0, debug_node_dealloc, node) ;
      break;
    default:
      rb_node = Data_Wrap_Struct(cNokogiriXmlNode, 0, debug_node_dealloc, node) ;
  }

  rb_hash_aset(node_cache, index, rb_node);
  rb_iv_set(rb_node, "@document", document);
  rb_funcall(rb_node, rb_intern("decorate!"), 0);
  return rb_node ;
}


void Nokogiri_xml_node_properties(xmlNodePtr node, VALUE attr_hash)
{
  xmlAttrPtr prop;
  xmlChar* propstr ;
  prop = node->properties ;
  while (prop != NULL) {
    propstr = xmlGetProp(node, prop->name) ;
    rb_hash_aset(attr_hash, rb_str_new2((const char*)prop->name),
                 rb_str_new2((char*)propstr));
    xmlFree(propstr);
    prop = prop->next ;
  }
}


#define XMLNS_PREFIX "xmlns"
#define XMLNS_PREFIX_LEN 6 /* including either colon or \0 */
#define XMLNS_BUFFER_LEN 128
void Nokogiri_xml_node_namespaces(xmlNodePtr node, VALUE attr_hash)
{
  xmlNsPtr ns;
  static char buffer[XMLNS_BUFFER_LEN] ;
  char *key ;
  size_t keylen ;

  if (node->type != XML_ELEMENT_NODE) return ;

  ns = node->nsDef;
  while (ns != NULL) {

    keylen = XMLNS_PREFIX_LEN + (ns->prefix ? (strlen((const char*)ns->prefix) + 1) : 0) ;
    if (keylen > XMLNS_BUFFER_LEN) {
      key = (char*)malloc(keylen) ;
    } else {
      key = buffer ;
    }

    if (ns->prefix) {
      sprintf(key, "%s:%s", XMLNS_PREFIX, ns->prefix);
    } else {
      sprintf(key, "%s", XMLNS_PREFIX);
    }

    rb_hash_aset(attr_hash, rb_str_new2(key), rb_str_new2((const char*)ns->href)) ;
    if (key != buffer) {
      free(key);
    }
    ns = ns->next ;
  }
}


VALUE cNokogiriXmlNode ;
void init_xml_node()
{
  /*
   * HACK.  This is so that rdoc will work with this C file.
   */
  /*
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE klass = rb_define_class_under(xml, "Node", rb_cObject);
  */

  VALUE klass = cNokogiriXmlNode = rb_const_get(mNokogiriXml, rb_intern("Node"));

  rb_define_singleton_method(klass, "new", new, 2);
  rb_define_singleton_method(klass, "new_from_str", new_from_str, 1);

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
  rb_define_method(klass, "path", path, 0);
  rb_define_method(klass, "key?", key_eh, 1);
  rb_define_method(klass, "blank?", blank_eh, 0);
  rb_define_method(klass, "[]=", set, 2);
  rb_define_method(klass, "remove_attribute", remove_prop, 1);
  rb_define_method(klass, "attributes", attributes, 0);
  rb_define_method(klass, "namespaces", namespaces, 0);
  rb_define_method(klass, "add_previous_sibling", add_previous_sibling, 1);
  rb_define_method(klass, "add_next_sibling", add_next_sibling, 1);
  rb_define_method(klass, "encode_special_chars", encode_special_chars, 1);
  rb_define_method(klass, "to_xml", to_xml, 0);
  rb_define_method(klass, "dup", duplicate_node, 0);
  rb_define_method(klass, "unlink", unlink_node, 0);
  rb_define_method(klass, "internal_subset", internal_subset, 0);
  rb_define_method(klass, "pointer_id", pointer_id, 0);

  rb_define_private_method(klass, "native_content=", set_content, 1);
  rb_define_private_method(klass, "get", get, 1);
}
