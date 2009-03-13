#include <xml_document.h>

static void dealloc(xmlDocPtr doc)
{
  NOKOGIRI_DEBUG_START(doc);

  nokogiriTuplePtr tuple = doc->_private;
  xmlNodeSetPtr node_set = tuple->unlinkedNodes;

  int i;
  for(i = 0; i < node_set->nodeNr; i++) {
    xmlAddChild((xmlNodePtr)doc, node_set->nodeTab[i]);
  }

  if (node_set->nodeTab != NULL)
    xmlFree(node_set->nodeTab);
  xmlFree(node_set);

  free(doc->_private);
  doc->_private = NULL;
  xmlFreeDoc(doc);

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

  xmlDocSetRootElement(doc, new_root);
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

  xmlInitParser();
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

  xmlInitParser();
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
  if(dup->type == XML_DOCUMENT_NODE)
    return Nokogiri_wrap_xml_document(cNokogiriXmlDocument, dup);
  else
    return Nokogiri_wrap_xml_document(cNokogiriHtmlDocument, dup);
}

/*
 * call-seq:
 *  new
 *
 * Create a new document
 */
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
 *    substitute_entities=(boolean)
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
 *    load_external_subsets=(boolean)
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
  rb_define_singleton_method(klass, "substitute_entities=", substitute_entities_set, 1);
  rb_define_singleton_method(klass, "load_external_subsets=", load_external_subsets_set, 1);

  rb_define_method(klass, "root", root, 0);
  rb_define_method(klass, "root=", set_root, 1);
  rb_define_method(klass, "encoding", encoding, 0);
  rb_define_method(klass, "dup", duplicate_node, -1);
  rb_define_method(klass, "url", url, 0);
}


/* this takes klass as a param because it's used for HtmlDocument, too. */
VALUE Nokogiri_wrap_xml_document(VALUE klass, xmlDocPtr doc)
{
  VALUE rb_doc = Qnil;
  nokogiriTuplePtr tuple = (nokogiriTuplePtr)malloc(sizeof(nokogiriTuple));

  rb_doc = Data_Wrap_Struct(
      klass ? klass : cNokogiriXmlDocument,
      0,
      dealloc,
      doc
  );
  rb_iv_set(rb_doc, "@decorators", Qnil);

  tuple->doc = (void *)rb_doc;
  tuple->unlinkedNodes = xmlXPathNodeSetCreate(NULL);
  doc->_private = tuple ;

  return rb_doc ;
}
