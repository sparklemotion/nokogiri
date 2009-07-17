#include <xml_document.h>

static int dealloc_node_i(xmlNodePtr key, xmlNodePtr node, xmlDocPtr doc)
{
  switch(node->type) {
  case XML_ATTRIBUTE_NODE:
    xmlFreePropList((xmlAttrPtr)node);
    break;
  default:
    if(node->parent == NULL) {
      xmlAddChild((xmlNodePtr)doc, node);
    }
  }
  return ST_CONTINUE;
}

static void dealloc(xmlDocPtr doc)
{
  NOKOGIRI_DEBUG_START(doc);

  st_table *node_hash = DOC_UNLINKED_NODE_HASH(doc);

  xmlDeregisterNodeFunc func = xmlDeregisterNodeDefault(NULL);

  st_foreach(node_hash, dealloc_node_i, (st_data_t)doc);
  st_free_table(node_hash);

  free(doc->_private);
  doc->_private = NULL;
  xmlFreeDoc(doc);

  xmlDeregisterNodeDefault(func);

  NOKOGIRI_DEBUG_END(doc);
}

/*
 * call-seq:
 *  url
 *
 * Get the url name for this document.
 */
static VALUE url(VALUE self)
{
  xmlDocPtr doc;
  Data_Get_Struct(self, xmlDoc, doc);

  if(doc->URL)
    return NOKOGIRI_STR_NEW2(doc->URL, doc->encoding);

  return Qnil;
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

  xmlNodePtr old_root = NULL;

  /* If the new root's document is not the same as the current document,
   * then we need to dup the node in to this document. */
  if(new_root->doc != doc) {
    old_root = xmlDocGetRootElement(doc);
    if (!(new_root = xmlDocCopyNode(new_root, doc, 1))) {
      rb_raise(rb_eRuntimeError, "Could not reparent node (xmlDocCopyNode)");
    }
  }

  xmlDocSetRootElement(doc, new_root);
  if(old_root) NOKOGIRI_ROOT_NODE(old_root);
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
  return Nokogiri_wrap_xml_node(Qnil, root) ;
}

/*
 * call-seq:
 *  encoding= encoding
 *
 * Set the encoding string for this Document
 */
static VALUE set_encoding(VALUE self, VALUE encoding)
{
  xmlDocPtr doc;
  Data_Get_Struct(self, xmlDoc, doc);

  doc->encoding = xmlStrdup((xmlChar *)StringValuePtr(encoding));

  return encoding;
}

/*
 * call-seq:
 *  encoding
 *
 * Get the encoding for this Document
 */
static VALUE encoding(VALUE self)
{
  xmlDocPtr doc;
  Data_Get_Struct(self, xmlDoc, doc);

  if(!doc->encoding) return Qnil;
  return NOKOGIRI_STR_NEW2(doc->encoding, doc->encoding);
}

/*
 * call-seq:
 *  read_io(io, url, encoding, options)
 *
 * Create a new document from an IO object
 */
static VALUE read_io( VALUE klass,
                      VALUE io,
                      VALUE url,
                      VALUE encoding,
                      VALUE options )
{
  const char * c_url    = (url == Qnil) ? NULL : StringValuePtr(url);
  const char * c_enc    = (encoding == Qnil) ? NULL : StringValuePtr(encoding);
  VALUE error_list      = rb_ary_new();

  xmlResetLastError();
  xmlSetStructuredErrorFunc((void *)error_list, Nokogiri_error_array_pusher);

  xmlDocPtr doc = xmlReadIO(
      (xmlInputReadCallback)io_read_callback,
      (xmlInputCloseCallback)io_close_callback,
      (void *)io,
      c_url,
      c_enc,
      NUM2INT(options)
  );
  xmlSetStructuredErrorFunc(NULL, NULL);

  if(doc == NULL) {
    xmlFreeDoc(doc);

    xmlErrorPtr error = xmlGetLastError();
    if(error)
      rb_funcall(rb_mKernel, rb_intern("raise"), 1,
          Nokogiri_wrap_xml_syntax_error((VALUE)NULL, error)
      );
    else
      rb_raise(rb_eRuntimeError, "Could not parse document");

    return Qnil;
  }

  VALUE document = Nokogiri_wrap_xml_document(klass, doc);
  rb_funcall(document, rb_intern("errors="), 1, error_list);
  return document;
}

/*
 * call-seq:
 *  read_memory(string, url, encoding, options)
 *
 * Create a new document from a String
 */
static VALUE read_memory( VALUE klass,
                          VALUE string,
                          VALUE url,
                          VALUE encoding,
                          VALUE options )
{
  const char * c_buffer = StringValuePtr(string);
  const char * c_url    = (url == Qnil) ? NULL : StringValuePtr(url);
  const char * c_enc    = (encoding == Qnil) ? NULL : StringValuePtr(encoding);
  int len               = RSTRING_LEN(string);
  VALUE error_list      = rb_ary_new();

  xmlResetLastError();
  xmlSetStructuredErrorFunc((void *)error_list, Nokogiri_error_array_pusher);
  xmlDocPtr doc = xmlReadMemory(c_buffer, len, c_url, c_enc, NUM2INT(options));
  xmlSetStructuredErrorFunc(NULL, NULL);

  if(doc == NULL) {
    xmlFreeDoc(doc);

    xmlErrorPtr error = xmlGetLastError();
    if(error)
      rb_funcall(rb_mKernel, rb_intern("raise"), 1,
          Nokogiri_wrap_xml_syntax_error((VALUE)NULL, error)
      );
    else
      rb_raise(rb_eRuntimeError, "Could not parse document");

    return Qnil;
  }

  VALUE document = Nokogiri_wrap_xml_document(klass, doc);
  rb_funcall(document, rb_intern("errors="), 1, error_list);
  return document;
}

/*
 * call-seq:
 *  dup
 *
 * Copy this Document.  An optional depth may be passed in, but it defaults
 * to a deep copy.  0 is a shallow copy, 1 is a deep copy.
 */
static VALUE duplicate_node(int argc, VALUE *argv, VALUE self)
{
  VALUE level;

  if(rb_scan_args(argc, argv, "01", &level) == 0)
    level = INT2NUM(1);

  xmlDocPtr doc, dup;
  Data_Get_Struct(self, xmlDoc, doc);

  dup = xmlCopyDoc(doc, NUM2INT(level));
  if(dup == NULL) return Qnil;

  dup->type = doc->type;
  return Nokogiri_wrap_xml_document(RBASIC(self)->klass, dup);
}

/*
 * call-seq:
 *  new(version = default)
 *
 * Create a new document with +version+ (defaults to "1.0")
 */
static VALUE new(int argc, VALUE *argv, VALUE klass)
{
  VALUE version, rest, rb_doc ;

  rb_scan_args(argc, argv, "0*", &rest);
  version = rb_ary_entry(rest, 0);
  if (version == Qnil) {
    version = rb_str_new2("1.0");
  }

  xmlDocPtr doc = xmlNewDoc((xmlChar *)StringValuePtr(version));
  rb_doc = Nokogiri_wrap_xml_document(klass, doc);
  rb_funcall2(rb_doc, rb_intern("initialize"), argc, argv);
  return rb_doc ;
}

VALUE cNokogiriXmlDocument ;
void init_xml_document()
{
  VALUE nokogiri  = rb_define_module("Nokogiri");
  VALUE xml       = rb_define_module_under(nokogiri, "XML");
  VALUE node      = rb_define_class_under(xml, "Node", rb_cObject);

  /*
   * Nokogiri::XML::Document wraps an xml document.
   */
  VALUE klass = rb_define_class_under(xml, "Document", node);

  cNokogiriXmlDocument = klass;

  rb_define_singleton_method(klass, "read_memory", read_memory, 4);
  rb_define_singleton_method(klass, "read_io", read_io, 4);
  rb_define_singleton_method(klass, "new", new, -1);

  rb_define_method(klass, "root", root, 0);
  rb_define_method(klass, "root=", set_root, 1);
  rb_define_method(klass, "encoding", encoding, 0);
  rb_define_method(klass, "encoding=", set_encoding, 1);
  rb_define_method(klass, "dup", duplicate_node, -1);
  rb_define_method(klass, "url", url, 0);
}


/* this takes klass as a param because it's used for HtmlDocument, too. */
VALUE Nokogiri_wrap_xml_document(VALUE klass, xmlDocPtr doc)
{
  nokogiriTuplePtr tuple = (nokogiriTuplePtr)malloc(sizeof(nokogiriTuple));

  VALUE rb_doc = Data_Wrap_Struct(
      klass ? klass : cNokogiriXmlDocument,
      0,
      dealloc,
      doc
  );

  VALUE cache = rb_ary_new();
  rb_iv_set(rb_doc, "@decorators", Qnil);
  rb_iv_set(rb_doc, "@node_cache", cache);
  rb_funcall(rb_doc, rb_intern("initialize"), 0);

  tuple->doc = (void *)rb_doc;
  tuple->unlinkedNodes = st_init_numtable_with_size(128);
  tuple->node_cache = cache;
  doc->_private = tuple ;

  return rb_doc ;
}
