#include <xml_document.h>

/*
 *  note that xmlDocPtr is being cast as an xmlNodePtr, which is legal for the
 *  "common part" struct header which contains only node pointers.
 */
static void gc_mark(xmlNodePtr node)
{
  VALUE rb_obj ;
  xmlNodePtr child ;
  /* mark children nodes */
  for (child = node->children ; child ; child = child->next) {
    if ((rb_obj = Nokogiri_xml_node2obj_get(child)) != Qnil)
      rb_gc_mark(rb_obj);
  }
}

static void dealloc(xmlDocPtr doc)
{
  NOKOGIRI_DEBUG_START(doc);
  Nokogiri_xml_node2obj_remove((xmlNodePtr)doc);
  doc->_private = NULL;
  xmlFreeDoc(doc);
  NOKOGIRI_DEBUG_END(doc);
}

/*
 * call-seq:
 *  serialize
 *
 * Serialize this document
 */
static VALUE serialize(VALUE self)
{
  xmlDocPtr doc;
  xmlChar *buf;
  int size;
  Data_Get_Struct(self, xmlDoc, doc);

  xmlDocDumpMemory(doc, &buf, &size);
  VALUE rb_str = rb_str_new((char *)buf, (long)size);
  xmlFree(buf);
  return rb_str;
}

/*
 * call-seq:
 *  root=
 *
 * Set the root element on this document
 */
static VALUE set_root(VALUE self, VALUE root)
{
  xmlDocPtr doc;
  xmlNodePtr new_root;

  Data_Get_Struct(self, xmlDoc, doc);
  Data_Get_Struct(root, xmlNode, new_root);

  xmlDocSetRootElement(doc, new_root);
  Nokogiri_xml_node_owned_set(new_root);
  return root;
}

/*
 * call-seq:
 *  root
 *
 * Get the root node for this document.
 */
static VALUE root(VALUE self)
{
  xmlDocPtr doc;
  Data_Get_Struct(self, xmlDoc, doc);

  xmlNodePtr root = xmlDocGetRootElement(doc);

  if(!root) return Qnil;
  return Nokogiri_wrap_xml_node(root) ;
}

static VALUE read_memory( VALUE klass,
                          VALUE string,
                          VALUE url,
                          VALUE encoding,
                          VALUE options )
{
  const char * c_buffer = StringValuePtr(string);
  const char * c_url    = (url == Qnil) ? NULL : StringValuePtr(url);
  const char * c_enc    = (encoding == Qnil) ? NULL : StringValuePtr(encoding);
  int len               = NUM2INT(rb_funcall(string, rb_intern("length"), 0));

  xmlInitParser();
  xmlDocPtr doc = xmlReadMemory(c_buffer, len, c_url, c_enc, NUM2INT(options));

  if(doc == NULL) {
    xmlFreeDoc(doc);
    rb_raise(rb_eRuntimeError, "Couldn't create a document");
  }

  return Nokogiri_wrap_xml_document(klass, doc);
}

static VALUE new(int argc, VALUE *argv, VALUE klass)
{
  VALUE version;
  if(rb_scan_args(argc, argv, "01", &version) == 0)
    version = rb_str_new2("1.0");

  xmlDocPtr doc = xmlNewDoc((xmlChar *)StringValuePtr(version));
  return Nokogiri_wrap_xml_document(klass, doc);
}

/*
 *  call-seq:
 *    substitute_entities_set bool)
 *
 *  Set the global XML default for substitute entities.
 */
static VALUE substitute_entities_set(VALUE klass, VALUE value)
{
    xmlSubstituteEntitiesDefault(NUM2INT(value));
    return Qnil ;
}

/*
 *  call-seq:
 *    substitute_entities_set bool)
 *
 *  Set the global XML default for load external subsets.
 */
static VALUE load_external_subsets_set(VALUE klass, VALUE value)
{
    xmlLoadExtDtdDefaultValue = NUM2INT(value);
    return Qnil ;
}

VALUE cNokogiriXmlDocument ;
void init_xml_document()
{
  VALUE klass = cNokogiriXmlDocument = rb_const_get(mNokogiriXml, rb_intern("Document"));

  rb_define_singleton_method(klass, "read_memory", read_memory, 4);
  rb_define_singleton_method(klass, "new", new, -1);
  rb_define_singleton_method(klass, "substitute_entities=", substitute_entities_set, 1);
  rb_define_singleton_method(klass, "load_external_subsets=", load_external_subsets_set, 1);

  rb_define_method(klass, "root", root, 0);
  rb_define_method(klass, "root=", set_root, 1);
  rb_define_method(klass, "serialize", serialize, 0);
  rb_undef_method(klass, "parent");
}


/* this takes klass as a param because it's used for HtmlDocument, too. */
VALUE Nokogiri_wrap_xml_document(VALUE klass, xmlDocPtr doc)
{
  VALUE rb_doc = Qnil;

  if ((rb_doc = Nokogiri_xml_node2obj_get((xmlNodePtr)doc)) != Qnil)
    return rb_doc ;

  rb_doc = Data_Wrap_Struct(klass ? klass : cNokogiriXmlDocument, gc_mark, dealloc, doc) ;
  doc->_private = (void *)rb_doc;

  Nokogiri_xml_node2obj_set((xmlNodePtr)doc, rb_doc);
  return rb_doc ;
}
