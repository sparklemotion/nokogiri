#include <nokogiri.h>

VALUE cNokogiriXmlDocument ;

static int
dealloc_node_i2(xmlNodePtr key, xmlNodePtr node, xmlDocPtr doc)
{
  switch (node->type) {
    case XML_ATTRIBUTE_NODE:
      xmlFreePropList((xmlAttrPtr)node);
      break;
    case XML_NAMESPACE_DECL:
      xmlFreeNs((xmlNsPtr)node);
      break;
    case XML_DTD_NODE:
      xmlFreeDtd((xmlDtdPtr)node);
      break;
    default:
      if (node->parent == NULL) {
        xmlAddChild((xmlNodePtr)doc, node);
      }
  }
  return ST_CONTINUE;
}

static int
dealloc_node_i(st_data_t key, st_data_t node, st_data_t doc)
{
  return dealloc_node_i2((xmlNodePtr)key, (xmlNodePtr)node, (xmlDocPtr)doc);
}

static void
remove_private(xmlNodePtr node)
{
  xmlNodePtr child;

  for (child = node->children; child; child = child->next) {
    remove_private(child);
  }

  if ((node->type == XML_ELEMENT_NODE ||
       node->type == XML_XINCLUDE_START ||
       node->type == XML_XINCLUDE_END) &&
      node->properties) {
    for (child = (xmlNodePtr)node->properties; child; child = child->next) {
      remove_private(child);
    }
  }

  node->_private = NULL;
}

static void
mark(void *data)
{
  xmlDocPtr doc = (xmlDocPtr)data;
  nokogiriTuplePtr tuple = (nokogiriTuplePtr)doc->_private;
  if (tuple) {
    rb_gc_mark(tuple->doc);
    rb_gc_mark(tuple->node_cache);
  }
}

static void
dealloc(void *data)
{
  xmlDocPtr doc = (xmlDocPtr)data;
  st_table *node_hash;

  node_hash  = DOC_UNLINKED_NODE_HASH(doc);

  st_foreach(node_hash, dealloc_node_i, (st_data_t)doc);
  st_free_table(node_hash);

  ruby_xfree(doc->_private);

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations" // xmlDeregisterNodeDefault is deprecated as of libxml2 2.11.0
  /*
   * libxml-ruby < 3.0.0 uses xmlDeregisterNodeDefault. If the user is using one of those older
   * versions, the registered callback from libxml-ruby will access the _private pointers set by
   * nokogiri, which will result in segfaults.
   *
   * To avoid this, we need to clear the _private pointers from all nodes in this document tree
   * before that callback gets invoked.
   *
   * libxml-ruby 3.0.0 was released in 2017-02, so at some point we can probably safely remove this
   * safeguard (though probably pairing with a runtime check on the libxml-ruby version).
   */
  if (xmlDeregisterNodeDefaultValue) {
    remove_private((xmlNodePtr)doc);
  }
#pragma GCC diagnostic pop

  xmlFreeDoc(doc);
}

static size_t
memsize_node(const xmlNodePtr node)
{
  /* note we don't count namespace definitions, just going for a good-enough number here */
  xmlNodePtr child;
  xmlAttrPtr property;
  size_t memsize = 0;

  memsize += xmlStrlen(node->name);

  if (node->type == XML_ELEMENT_NODE) {
    for (property = node->properties; property; property = property->next) {
      memsize += sizeof(xmlAttr) + memsize_node((xmlNodePtr)property);
    }
  }
  if (node->type == XML_TEXT_NODE) {
    memsize += xmlStrlen(node->content);
  }
  for (child = node->children; child; child = child->next) {
    memsize += sizeof(xmlNode) + memsize_node(child);
  }
  return memsize;
}

static size_t
memsize(const void *data)
{
  xmlDocPtr doc = (const xmlDocPtr)data;
  size_t memsize = sizeof(xmlDoc);
  /* This may not account for all memory use */
  memsize += memsize_node((xmlNodePtr)doc);
  return memsize;
}

static const rb_data_type_t noko_xml_document_data_type = {
  .wrap_struct_name = "Nokogiri::XML::Document",
  .function = {
    .dmark = mark,
    .dfree = dealloc,
    .dsize = memsize,
  },
  // .flags = RUBY_TYPED_FREE_IMMEDIATELY, // TODO see https://github.com/sparklemotion/nokogiri/issues/2822
};

static void
recursively_remove_namespaces_from_node(xmlNodePtr node)
{
  xmlNodePtr child ;
  xmlAttrPtr property ;

  xmlSetNs(node, NULL);

  for (child = node->children ; child ; child = child->next) {
    recursively_remove_namespaces_from_node(child);
  }

  if (((node->type == XML_ELEMENT_NODE) ||
       (node->type == XML_XINCLUDE_START) ||
       (node->type == XML_XINCLUDE_END)) &&
      node->nsDef) {
    xmlNsPtr curr = node->nsDef;
    while (curr) {
      noko_xml_document_pin_namespace(curr, node->doc);
      curr = curr->next;
    }
    node->nsDef = NULL;
  }

  if (node->type == XML_ELEMENT_NODE && node->properties != NULL) {
    property = node->properties ;
    while (property != NULL) {
      if (property->ns) { property->ns = NULL ; }
      property = property->next ;
    }
  }
}

/*
 * call-seq:
 *  url
 *
 * Get the url name for this document.
 */
static VALUE
url(VALUE self)
{
  xmlDocPtr doc = noko_xml_document_unwrap(self);

  if (doc->URL) { return NOKOGIRI_STR_NEW2(doc->URL); }

  return Qnil;
}

/*
 * call-seq:
 *  root=
 *
 * Set the root element on this document
 */
static VALUE
rb_xml_document_root_set(VALUE self, VALUE rb_new_root)
{
  xmlDocPtr c_document;
  xmlNodePtr c_new_root = NULL, c_current_root;

  c_document = noko_xml_document_unwrap(self);

  c_current_root = xmlDocGetRootElement(c_document);
  if (c_current_root) {
    xmlUnlinkNode(c_current_root);
    noko_xml_document_pin_node(c_current_root);
  }

  if (!NIL_P(rb_new_root)) {
    if (!rb_obj_is_kind_of(rb_new_root, cNokogiriXmlNode)) {
      rb_raise(rb_eArgError,
               "expected Nokogiri::XML::Node but received %"PRIsVALUE,
               rb_obj_class(rb_new_root));
    }

    Noko_Node_Get_Struct(rb_new_root, xmlNode, c_new_root);

    /* If the new root's document is not the same as the current document,
     * then we need to dup the node in to this document. */
    if (c_new_root->doc != c_document) {
      c_new_root = xmlDocCopyNode(c_new_root, c_document, 1);
      if (!c_new_root) {
        rb_raise(rb_eRuntimeError, "Could not reparent node (xmlDocCopyNode)");
      }
    }
  }

  xmlDocSetRootElement(c_document, c_new_root);

  return rb_new_root;
}

/*
 * call-seq:
 *  root
 *
 * Get the root node for this document.
 */
static VALUE
rb_xml_document_root(VALUE self)
{
  xmlDocPtr c_document;
  xmlNodePtr c_root;

  c_document = noko_xml_document_unwrap(self);

  c_root = xmlDocGetRootElement(c_document);
  if (!c_root) {
    return Qnil;
  }

  return noko_xml_node_wrap(Qnil, c_root) ;
}

/*
 * call-seq:
 *  encoding= encoding
 *
 * Set the encoding string for this Document
 */
static VALUE
set_encoding(VALUE self, VALUE encoding)
{
  xmlDocPtr doc = noko_xml_document_unwrap(self);

  if (doc->encoding) {
    xmlFree(DISCARD_CONST_QUAL_XMLCHAR(doc->encoding));
  }

  doc->encoding = xmlStrdup((xmlChar *)StringValueCStr(encoding));

  return encoding;
}

/*
 * call-seq:
 *  encoding
 *
 * Get the encoding for this Document
 */
static VALUE
encoding(VALUE self)
{
  xmlDocPtr doc = noko_xml_document_unwrap(self);

  if (!doc->encoding) { return Qnil; }
  return NOKOGIRI_STR_NEW2(doc->encoding);
}

/*
 * call-seq:
 *  version
 *
 * Get the XML version for this Document
 */
static VALUE
version(VALUE self)
{
  xmlDocPtr doc = noko_xml_document_unwrap(self);

  if (!doc->version) { return Qnil; }
  return NOKOGIRI_STR_NEW2(doc->version);
}

/*
 * call-seq:
 *  read_io(io, url, encoding, options)
 *
 * Create a new document from an IO object
 */
static VALUE
read_io(VALUE klass,
        VALUE io,
        VALUE url,
        VALUE encoding,
        VALUE options)
{
  const char *c_url    = NIL_P(url)      ? NULL : StringValueCStr(url);
  const char *c_enc    = NIL_P(encoding) ? NULL : StringValueCStr(encoding);
  VALUE error_list      = rb_ary_new();
  VALUE document;
  xmlDocPtr doc;

  xmlResetLastError();
  xmlSetStructuredErrorFunc((void *)error_list, Nokogiri_error_array_pusher);

  doc = xmlReadIO(
          (xmlInputReadCallback)noko_io_read,
          (xmlInputCloseCallback)noko_io_close,
          (void *)io,
          c_url,
          c_enc,
          (int)NUM2INT(options)
        );
  xmlSetStructuredErrorFunc(NULL, NULL);

  if (doc == NULL) {
    xmlErrorConstPtr error;

    xmlFreeDoc(doc);

    error = xmlGetLastError();
    if (error) {
      rb_exc_raise(Nokogiri_wrap_xml_syntax_error(error));
    } else {
      rb_raise(rb_eRuntimeError, "Could not parse document");
    }

    return Qnil;
  }

  document = noko_xml_document_wrap(klass, doc);
  rb_iv_set(document, "@errors", error_list);
  return document;
}

/*
 * call-seq:
 *  read_memory(string, url, encoding, options)
 *
 * Create a new document from a String
 */
static VALUE
read_memory(VALUE klass,
            VALUE string,
            VALUE url,
            VALUE encoding,
            VALUE options)
{
  const char *c_buffer = StringValuePtr(string);
  const char *c_url    = NIL_P(url)      ? NULL : StringValueCStr(url);
  const char *c_enc    = NIL_P(encoding) ? NULL : StringValueCStr(encoding);
  int len               = (int)RSTRING_LEN(string);
  VALUE error_list      = rb_ary_new();
  VALUE document;
  xmlDocPtr doc;

  xmlResetLastError();
  xmlSetStructuredErrorFunc((void *)error_list, Nokogiri_error_array_pusher);
  doc = xmlReadMemory(c_buffer, len, c_url, c_enc, (int)NUM2INT(options));
  xmlSetStructuredErrorFunc(NULL, NULL);

  if (doc == NULL) {
    xmlErrorConstPtr error;

    xmlFreeDoc(doc);

    error = xmlGetLastError();
    if (error) {
      rb_exc_raise(Nokogiri_wrap_xml_syntax_error(error));
    } else {
      rb_raise(rb_eRuntimeError, "Could not parse document");
    }

    return Qnil;
  }

  document = noko_xml_document_wrap(klass, doc);
  rb_iv_set(document, "@errors", error_list);
  return document;
}

/*
 * call-seq:
 *  dup
 *
 * Copy this Document.  An optional depth may be passed in, but it defaults
 * to a deep copy.  0 is a shallow copy, 1 is a deep copy.
 */
static VALUE
duplicate_document(int argc, VALUE *argv, VALUE self)
{
  xmlDocPtr doc, dup;
  VALUE copy;
  VALUE level;

  if (rb_scan_args(argc, argv, "01", &level) == 0) {
    level = INT2NUM((long)1);
  }

  doc = noko_xml_document_unwrap(self);

  dup = xmlCopyDoc(doc, (int)NUM2INT(level));

  if (dup == NULL) { return Qnil; }

  dup->type = doc->type;
  copy = noko_xml_document_wrap(rb_obj_class(self), dup);
  rb_iv_set(copy, "@errors", rb_iv_get(self, "@errors"));
  return copy ;
}

/*
 * call-seq:
 *  new(version = default)
 *
 * Create a new document with +version+ (defaults to "1.0")
 */
static VALUE
new (int argc, VALUE *argv, VALUE klass)
{
  xmlDocPtr doc;
  VALUE version, rest, rb_doc ;

  rb_scan_args(argc, argv, "0*", &rest);
  version = rb_ary_entry(rest, (long)0);
  if (NIL_P(version)) { version = rb_str_new2("1.0"); }

  doc = xmlNewDoc((xmlChar *)StringValueCStr(version));
  rb_doc = noko_xml_document_wrap_with_init_args(klass, doc, argc, argv);
  return rb_doc ;
}

/*
 *  call-seq:
 *    remove_namespaces!
 *
 *  Remove all namespaces from all nodes in the document.
 *
 *  This could be useful for developers who either don't understand namespaces
 *  or don't care about them.
 *
 *  The following example shows a use case, and you can decide for yourself
 *  whether this is a good thing or not:
 *
 *    doc = Nokogiri::XML <<-EOXML
 *       <root>
 *         <car xmlns:part="http://general-motors.com/">
 *           <part:tire>Michelin Model XGV</part:tire>
 *         </car>
 *         <bicycle xmlns:part="http://schwinn.com/">
 *           <part:tire>I'm a bicycle tire!</part:tire>
 *         </bicycle>
 *       </root>
 *       EOXML
 *
 *    doc.xpath("//tire").to_s # => ""
 *    doc.xpath("//part:tire", "part" => "http://general-motors.com/").to_s # => "<part:tire>Michelin Model XGV</part:tire>"
 *    doc.xpath("//part:tire", "part" => "http://schwinn.com/").to_s # => "<part:tire>I'm a bicycle tire!</part:tire>"
 *
 *    doc.remove_namespaces!
 *
 *    doc.xpath("//tire").to_s # => "<tire>Michelin Model XGV</tire><tire>I'm a bicycle tire!</tire>"
 *    doc.xpath("//part:tire", "part" => "http://general-motors.com/").to_s # => ""
 *    doc.xpath("//part:tire", "part" => "http://schwinn.com/").to_s # => ""
 *
 *  For more information on why this probably is *not* a good thing in general,
 *  please direct your browser to
 *  http://tenderlovemaking.com/2009/04/23/namespaces-in-xml.html
 */
static VALUE
remove_namespaces_bang(VALUE self)
{
  xmlDocPtr doc = noko_xml_document_unwrap(self);

  recursively_remove_namespaces_from_node((xmlNodePtr)doc);
  return self;
}

/* call-seq: doc.create_entity(name, type, external_id, system_id, content)
 *
 * Create a new entity named +name+.
 *
 * +type+ is an integer representing the type of entity to be created, and it
 * defaults to Nokogiri::XML::EntityDecl::INTERNAL_GENERAL.  See
 * the constants on Nokogiri::XML::EntityDecl for more information.
 *
 * +external_id+, +system_id+, and +content+ set the External ID, System ID,
 * and content respectively.  All of these parameters are optional.
 */
static VALUE
create_entity(int argc, VALUE *argv, VALUE self)
{
  VALUE name;
  VALUE type;
  VALUE external_id;
  VALUE system_id;
  VALUE content;
  xmlEntityPtr ptr;
  xmlDocPtr doc ;

  doc = noko_xml_document_unwrap(self);

  rb_scan_args(argc, argv, "14", &name, &type, &external_id, &system_id,
               &content);

  xmlResetLastError();
  ptr = xmlAddDocEntity(
          doc,
          (xmlChar *)(NIL_P(name)        ? NULL                        : StringValueCStr(name)),
          (int)(NIL_P(type)        ? XML_INTERNAL_GENERAL_ENTITY : NUM2INT(type)),
          (xmlChar *)(NIL_P(external_id) ? NULL                        : StringValueCStr(external_id)),
          (xmlChar *)(NIL_P(system_id)   ? NULL                        : StringValueCStr(system_id)),
          (xmlChar *)(NIL_P(content)     ? NULL                        : StringValueCStr(content))
        );

  if (NULL == ptr) {
    xmlErrorConstPtr error = xmlGetLastError();
    if (error) {
      rb_exc_raise(Nokogiri_wrap_xml_syntax_error(error));
    } else {
      rb_raise(rb_eRuntimeError, "Could not create entity");
    }

    return Qnil;
  }

  return noko_xml_node_wrap(cNokogiriXmlEntityDecl, (xmlNodePtr)ptr);
}

static int
block_caller(void *ctx, xmlNodePtr c_node, xmlNodePtr c_parent_node)
{
  VALUE block = (VALUE)ctx;
  VALUE rb_node;
  VALUE rb_parent_node;
  VALUE ret;

  if (c_node->type == XML_NAMESPACE_DECL) {
    rb_node = noko_xml_namespace_wrap((xmlNsPtr)c_node, c_parent_node->doc);
  } else {
    rb_node = noko_xml_node_wrap(Qnil, c_node);
  }
  rb_parent_node = c_parent_node ? noko_xml_node_wrap(Qnil, c_parent_node) : Qnil;

  ret = rb_funcall(block, rb_intern("call"), 2, rb_node, rb_parent_node);

  return (Qfalse == ret || Qnil == ret) ? 0 : 1;
}

/* call-seq:
 *  doc.canonicalize(mode=XML_C14N_1_0,inclusive_namespaces=nil,with_comments=false)
 *  doc.canonicalize { |obj, parent| ... }
 *
 * Canonicalize a document and return the results.  Takes an optional block
 * that takes two parameters: the +obj+ and that node's +parent+.
 * The  +obj+ will be either a Nokogiri::XML::Node, or a Nokogiri::XML::Namespace
 * The block must return a non-nil, non-false value if the +obj+ passed in
 * should be included in the canonicalized document.
 */
static VALUE
rb_xml_document_canonicalize(int argc, VALUE *argv, VALUE self)
{
  VALUE rb_mode;
  VALUE rb_namespaces;
  VALUE rb_comments_p;
  int c_mode = 0;
  xmlChar **c_namespaces;

  xmlDocPtr c_doc;
  xmlOutputBufferPtr c_obuf;
  xmlC14NIsVisibleCallback c_callback_wrapper = NULL;
  void *rb_callback = NULL;

  VALUE rb_cStringIO;
  VALUE rb_io;

  rb_scan_args(argc, argv, "03", &rb_mode, &rb_namespaces, &rb_comments_p);
  if (!NIL_P(rb_mode)) {
    Check_Type(rb_mode, T_FIXNUM);
    c_mode = NUM2INT(rb_mode);
  }
  if (!NIL_P(rb_namespaces)) {
    Check_Type(rb_namespaces, T_ARRAY);
    if (c_mode == XML_C14N_1_0 || c_mode == XML_C14N_1_1) {
      rb_raise(rb_eRuntimeError, "This canonicalizer does not support this operation");
    }
  }

  c_doc = noko_xml_document_unwrap(self);

  rb_cStringIO = rb_const_get_at(rb_cObject, rb_intern("StringIO"));
  rb_io = rb_class_new_instance(0, 0, rb_cStringIO);
  c_obuf = xmlAllocOutputBuffer(NULL);

  c_obuf->writecallback = (xmlOutputWriteCallback)noko_io_write;
  c_obuf->closecallback = (xmlOutputCloseCallback)noko_io_close;
  c_obuf->context = (void *)rb_io;

  if (rb_block_given_p()) {
    c_callback_wrapper = block_caller;
    rb_callback = (void *)rb_block_proc();
  }

  if (NIL_P(rb_namespaces)) {
    c_namespaces = NULL;
  } else {
    long ns_len = RARRAY_LEN(rb_namespaces);
    c_namespaces = ruby_xcalloc((size_t)ns_len + 1, sizeof(xmlChar *));
    for (int j = 0 ; j < ns_len ; j++) {
      VALUE entry = rb_ary_entry(rb_namespaces, j);
      c_namespaces[j] = (xmlChar *)StringValueCStr(entry);
    }
  }

  xmlC14NExecute(c_doc, c_callback_wrapper, rb_callback,
                 c_mode,
                 c_namespaces,
                 (int)RTEST(rb_comments_p),
                 c_obuf);

  ruby_xfree(c_namespaces);
  xmlOutputBufferClose(c_obuf);

  return rb_funcall(rb_io, rb_intern("string"), 0);
}

VALUE
noko_xml_document_wrap_with_init_args(VALUE klass, xmlDocPtr c_document, int argc, VALUE *argv)
{
  VALUE rb_document;
  nokogiriTuplePtr tuple;

  if (!klass) {
    klass = cNokogiriXmlDocument;
  }

  rb_document = TypedData_Wrap_Struct(klass, &noko_xml_document_data_type, c_document);

  tuple = (nokogiriTuplePtr)ruby_xmalloc(sizeof(nokogiriTuple));
  tuple->doc = rb_document;
  tuple->unlinkedNodes = st_init_numtable_with_size(128);
  tuple->node_cache = rb_ary_new();

  c_document->_private = tuple ;

  rb_iv_set(rb_document, "@decorators", Qnil);
  rb_iv_set(rb_document, "@errors", Qnil);
  rb_iv_set(rb_document, "@node_cache", tuple->node_cache);

  rb_obj_call_init(rb_document, argc, argv);

  return rb_document ;
}


/* deprecated. use noko_xml_document_wrap() instead. */
VALUE
Nokogiri_wrap_xml_document(VALUE klass, xmlDocPtr doc)
{
  /* TODO: deprecate this method in v2.0 */
  return noko_xml_document_wrap_with_init_args(klass, doc, 0, NULL);
}

VALUE
noko_xml_document_wrap(VALUE klass, xmlDocPtr doc)
{
  return noko_xml_document_wrap_with_init_args(klass, doc, 0, NULL);
}

xmlDocPtr
noko_xml_document_unwrap(VALUE rb_document)
{
  xmlDocPtr c_document;
  TypedData_Get_Struct(rb_document, xmlDoc, &noko_xml_document_data_type, c_document);
  return c_document;
}

/* Schema creation will remove and deallocate "blank" nodes.
 * If those blank nodes have been exposed to Ruby, they could get freed
 * out from under the VALUE pointer.  This function checks to see if any of
 * those nodes have been exposed to Ruby, and if so we should raise an exception.
 */
int
noko_xml_document_has_wrapped_blank_nodes_p(xmlDocPtr c_document)
{
  VALUE cache = DOC_NODE_CACHE(c_document);

  if (NIL_P(cache)) {
    return 0;
  }

  for (long jnode = 0; jnode < RARRAY_LEN(cache); jnode++) {
    xmlNodePtr node;
    VALUE element = rb_ary_entry(cache, jnode);

    Noko_Node_Get_Struct(element, xmlNode, node);
    if (xmlIsBlankNode(node)) {
      return 1;
    }
  }

  return 0;
}

void
noko_xml_document_pin_node(xmlNodePtr node)
{
  xmlDocPtr doc;
  nokogiriTuplePtr tuple;

  doc = node->doc;
  tuple = (nokogiriTuplePtr)doc->_private;
  st_insert(tuple->unlinkedNodes, (st_data_t)node, (st_data_t)node);
}


void
noko_xml_document_pin_namespace(xmlNsPtr ns, xmlDocPtr doc)
{
  nokogiriTuplePtr tuple;

  tuple = (nokogiriTuplePtr)doc->_private;
  st_insert(tuple->unlinkedNodes, (st_data_t)ns, (st_data_t)ns);
}


void
noko_init_xml_document(void)
{
  assert(cNokogiriXmlNode);
  /*
   * Nokogiri::XML::Document wraps an xml document.
   */
  cNokogiriXmlDocument = rb_define_class_under(mNokogiriXml, "Document", cNokogiriXmlNode);

  rb_define_singleton_method(cNokogiriXmlDocument, "read_memory", read_memory, 4);
  rb_define_singleton_method(cNokogiriXmlDocument, "read_io", read_io, 4);
  rb_define_singleton_method(cNokogiriXmlDocument, "new", new, -1);

  rb_define_method(cNokogiriXmlDocument, "root", rb_xml_document_root, 0);
  rb_define_method(cNokogiriXmlDocument, "root=", rb_xml_document_root_set, 1);
  rb_define_method(cNokogiriXmlDocument, "encoding", encoding, 0);
  rb_define_method(cNokogiriXmlDocument, "encoding=", set_encoding, 1);
  rb_define_method(cNokogiriXmlDocument, "version", version, 0);
  rb_define_method(cNokogiriXmlDocument, "canonicalize", rb_xml_document_canonicalize, -1);
  rb_define_method(cNokogiriXmlDocument, "dup", duplicate_document, -1);
  rb_define_method(cNokogiriXmlDocument, "url", url, 0);
  rb_define_method(cNokogiriXmlDocument, "create_entity", create_entity, -1);
  rb_define_method(cNokogiriXmlDocument, "remove_namespaces!", remove_namespaces_bang, 0);
}
