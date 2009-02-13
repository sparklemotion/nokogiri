#include <xml_node_set.h>
#include <libxml/xpathInternals.h>
/*
 * call-seq:
 *  length
 *
 * Get the length of the node set
 */
static VALUE length(VALUE self)
{
  xmlNodeSetPtr node_set;
  Data_Get_Struct(self, xmlNodeSet, node_set);

  if(node_set)
    return INT2NUM(node_set->nodeNr);

  return INT2NUM(0);
}

/*
 * call-seq:
 *  push(node)
 *
 * Append +node+ to the NodeSet.
 */
static VALUE push(VALUE self, VALUE rb_node)
{
  xmlNodeSetPtr node_set;
  xmlNodePtr node;

  if(! rb_funcall(rb_node, rb_intern("is_a?"), 1, cNokogiriXmlNode))
    rb_raise(rb_eArgError, "node must be a Nokogiri::XML::Node");

  Data_Get_Struct(self, xmlNodeSet, node_set);
  Data_Get_Struct(rb_node, xmlNode, node);
  xmlXPathNodeSetAdd(node_set, node);
  return self;
}

/*
 * call-seq:
 *  [](i)
 *
 * Get the node at index +i+
 */
static VALUE index_at(VALUE self, VALUE number)
{
  int i = NUM2INT(number);
  xmlNodeSetPtr node_set;
  Data_Get_Struct(self, xmlNodeSet, node_set);

  if(i >= node_set->nodeNr || abs(i) > node_set->nodeNr)
    return Qnil;

  if(i < 0)
    i = i + node_set->nodeNr;

  return Nokogiri_wrap_xml_node(node_set->nodeTab[i]);
}

static void deallocate(xmlNodeSetPtr node_set)
{
  /*
   *  xmlXPathFreeNodeSet() contains an implicit assumption that it is being
   *  called before any of its pointed-to nodes have been free()d. this
   *  assumption lies in the operation where it dereferences nodeTab pointers
   *  while searching for namespace nodes to free.
   *
   *  however, since Ruby's GC mechanism cannot guarantee the strict order in
   *  which ruby objects will be GC'd, nodes may be garbage collected before a
   *  nodeset containing pointers to those nodes. (this is true regardless of
   *  how we declare dependencies between objects with rb_gc_mark().)
   *
   *  as a result, xmlXPathFreeNodeSet() will perform unsafe memory operations,
   *  and calling it would be evil.
   *
   *  on the bright side, though, Nokogiri's API currently does not cause
   *  namespace nodes to be included in node sets, ever.
   *
   *  armed with that fact, we examined xmlXPathFreeNodeSet() and related libxml
   *  code and determined that, within the Nokogiri abstraction, we will not
   *  leak memory if we simply free the node set's memory directly. that's only
   *  quasi-evil!
   *
   *  there's probably a lesson in here somewhere about intermingling, within a
   *  single array, structs with different memory-ownership semantics. or more
   *  generally, a lesson about building an API in C/C++ that does not contain
   *  assumptions about the strict order in which memory will be released. hey,
   *  that sounds like a great idea for a blog post! get to it!
   *
   *  "In Valgrind We Trust." seriously.
   */
  NOKOGIRI_DEBUG_START(node_set) ;
  if (node_set->nodeTab != NULL)
    xmlFree(node_set->nodeTab);
  xmlFree(node_set);
  NOKOGIRI_DEBUG_END(node_set) ;
}

static VALUE allocate(VALUE klass)
{
  return Nokogiri_wrap_xml_node_set(xmlXPathNodeSetCreate(NULL));
}

VALUE Nokogiri_wrap_xml_node_set(xmlNodeSetPtr node_set)
{
  return Data_Wrap_Struct(cNokogiriXmlNodeSet, 0, deallocate, node_set);
}

VALUE cNokogiriXmlNodeSet ;
void init_xml_node_set(void)
{
  VALUE nokogiri  = rb_define_module("Nokogiri");
  VALUE xml       = rb_define_module_under(nokogiri, "XML");
  VALUE klass     = rb_define_class_under(xml, "NodeSet", rb_cObject);
  cNokogiriXmlNodeSet = klass;

  rb_define_alloc_func(klass, allocate);
  rb_define_method(klass, "length", length, 0);
  rb_define_method(klass, "[]", index_at, 1);
  rb_define_method(klass, "push", push, 1);
}
