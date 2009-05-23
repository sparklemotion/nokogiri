#include <xml_reader.h>

static void dealloc(xmlTextReaderPtr reader)
{
  NOKOGIRI_DEBUG_START(reader);
  xmlFreeTextReader(reader);
  NOKOGIRI_DEBUG_END(reader);
}

static int has_attributes(xmlTextReaderPtr reader)
{
  /*
   *  this implementation of xmlTextReaderHasAttributes explicitly includes
   *  namespaces and properties, because some earlier versions ignore
   *  namespaces.
   */
  xmlNodePtr node ;
  node = xmlTextReaderCurrentNode(reader);
  if (node == NULL)
    return(0);

  if ((node->type == XML_ELEMENT_NODE) &&
      ((node->properties != NULL) || (node->nsDef != NULL)))
    return(1);
  return(0);
}

#define XMLNS_PREFIX "xmlns"
#define XMLNS_PREFIX_LEN 6 /* including either colon or \0 */
#define XMLNS_BUFFER_LEN 128
static void Nokogiri_xml_node_namespaces(xmlNodePtr node, VALUE attr_hash)
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

    rb_hash_aset(attr_hash,
        NOKOGIRI_STR_NEW2(key, node->doc->encoding),
        (ns->href ? NOKOGIRI_STR_NEW2(ns->href, node->doc->encoding) : Qnil)
    );
    if (key != buffer) {
      free(key);
    }
    ns = ns->next ;
  }
}


/*
 * call-seq:
 *   default?
 *
 * Was an attribute generated from the default value in the DTD or schema?
 */
static VALUE default_eh(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);
  int eh = xmlTextReaderIsDefault(reader);
  if(eh == 0) return Qfalse;
  if(eh == 1) return Qtrue;

  return Qnil;
}

/*
 * call-seq:
 *   value?
 *
 * Does this node have a text value?
 */
static VALUE value_eh(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);
  int eh = xmlTextReaderHasValue(reader);
  if(eh == 0) return Qfalse;
  if(eh == 1) return Qtrue;

  return Qnil;
}

/*
 * call-seq:
 *   attributes?
 *
 * Does this node have attributes?
 */
static VALUE attributes_eh(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);
  int eh = has_attributes(reader);
  if(eh == 0) return Qfalse;
  if(eh == 1) return Qtrue;

  return Qnil;
}

/*
 * call-seq:
 *   namespaces
 *
 * Get a hash of namespaces for this Node
 */
static VALUE namespaces(VALUE self)
{
  xmlTextReaderPtr reader;
  VALUE attr ;

  Data_Get_Struct(self, xmlTextReader, reader);

  attr = rb_hash_new() ;

  if (! has_attributes(reader))
    return attr ;

  xmlNodePtr ptr = xmlTextReaderExpand(reader);
  if(ptr == NULL) return Qnil;

  Nokogiri_xml_node_namespaces(ptr, attr);

  return attr ;
}

/*
 * call-seq:
 *   attribute_nodes
 *
 * Get a list of attributes for this Node
 */
static VALUE attribute_nodes(VALUE self)
{
  xmlTextReaderPtr reader;
  VALUE attr ;

  Data_Get_Struct(self, xmlTextReader, reader);

  attr = rb_ary_new() ;

  if (! has_attributes(reader))
    return attr ;

  xmlNodePtr ptr = xmlTextReaderExpand(reader);
  if(ptr == NULL) return Qnil;

  // FIXME I'm not sure if this is correct.....  I don't really like pointing
  // at this document, but I have to because of the assertions in
  // the node wrapping code.
  if(! DOC_RUBY_OBJECT_TEST(ptr->doc)) {
    VALUE rb_doc = Nokogiri_wrap_xml_document(cNokogiriXmlDocument, ptr->doc);
    RDATA(rb_doc)->dfree = NULL;
  }
  VALUE enc = rb_iv_get(self, "@encoding");

  if(enc != Qnil && NULL == ptr->doc->encoding) {
    ptr->doc->encoding = calloc((size_t)RSTRING_LEN(enc), sizeof(char));
    strncpy(
      (char *)ptr->doc->encoding,
      StringValuePtr(enc),
      (size_t)RSTRING_LEN(enc)
    );
  }

  Nokogiri_xml_node_properties(ptr, attr);

  return attr ;
}

/*
 * call-seq:
 *   attribute_at(index)
 *
 * Get the value of attribute at +index+
 */
static VALUE attribute_at(VALUE self, VALUE index)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);

  if(index == Qnil) return Qnil;
  index = rb_funcall(index, rb_intern("to_i"), 0);

  xmlChar * value = xmlTextReaderGetAttributeNo(
      reader,
      NUM2INT(index)
  );
  if(value == NULL) return Qnil;

  VALUE MAYBE_UNUSED(enc) = rb_iv_get(self, "@encoding");
  VALUE rb_value = NOKOGIRI_STR_NEW2(value,
      RTEST(enc) ? StringValuePtr(enc) : NULL);
  xmlFree(value);
  return rb_value;
}

/*
 * call-seq:
 *   attribute(name)
 *
 * Get the value of attribute named +name+
 */
static VALUE reader_attribute(VALUE self, VALUE name)
{
  xmlTextReaderPtr reader;
  xmlChar *value ;
  Data_Get_Struct(self, xmlTextReader, reader);

  if(name == Qnil) return Qnil;
  name = StringValue(name) ;

  value = xmlTextReaderGetAttribute(reader, (xmlChar*)StringValuePtr(name));
  if(value == NULL) {
    /* this section is an attempt to workaround older versions of libxml that
       don't handle namespaces properly in all attribute-and-friends functions */
    xmlChar *prefix = NULL ;
    xmlChar *localname = xmlSplitQName2((xmlChar*)StringValuePtr(name), &prefix);
    if (localname != NULL) {
      value = xmlTextReaderLookupNamespace(reader, localname);
      xmlFree(localname) ;
    } else {
      value = xmlTextReaderLookupNamespace(reader, prefix);
    }
    xmlFree(prefix);
  }
  if(value == NULL) return Qnil;

  VALUE MAYBE_UNUSED(enc) = rb_iv_get(self, "@encoding");
  VALUE rb_value = NOKOGIRI_STR_NEW2(value,
      RTEST(enc) ? StringValuePtr(enc) : NULL);
  xmlFree(value);
  return rb_value;
}

/*
 * call-seq:
 *   attribute_count
 *
 * Get the number of attributes for the current node
 */
static VALUE attribute_count(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);
  int count = xmlTextReaderAttributeCount(reader);
  if(count == -1) return Qnil;

  return INT2NUM(count);
}

/*
 * call-seq:
 *   depth
 *
 * Get the depth of the node
 */
static VALUE depth(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);
  int depth = xmlTextReaderDepth(reader);
  if(depth == -1) return Qnil;

  return INT2NUM(depth);
}

/*
 * call-seq:
 *   xml_version
 *
 * Get the XML version of the document being read
 */
static VALUE xml_version(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);
  const char * version = (const char *)xmlTextReaderConstXmlVersion(reader);
  if(version == NULL) return Qnil;

  return NOKOGIRI_STR_NEW2(version, "UTF-8");
}

/*
 * call-seq:
 *   lang
 *
 * Get the xml:lang scope within which the node resides.
 */
static VALUE lang(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);
  const char * lang = (const char *)xmlTextReaderConstXmlLang(reader);
  if(lang == NULL) return Qnil;

  VALUE MAYBE_UNUSED(enc) = rb_iv_get(self, "@encoding");
  return NOKOGIRI_STR_NEW2(lang,
      RTEST(enc) ? StringValuePtr(enc) : NULL);
}

/*
 * call-seq:
 *   value
 *
 * Get the text value of the node if present
 */
static VALUE value(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);
  const char * value = (const char *)xmlTextReaderConstValue(reader);
  if(value == NULL) return Qnil;

  VALUE MAYBE_UNUSED(enc) = rb_iv_get(self, "@encoding");
  return NOKOGIRI_STR_NEW2(value,
      RTEST(enc) ? StringValuePtr(enc) : NULL);
}

/*
 * call-seq:
 *   prefix
 *
 * Get the shorthand reference to the namespace associated with the node.
 */
static VALUE prefix(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);
  const char * prefix = (const char *)xmlTextReaderConstPrefix(reader);
  if(prefix == NULL) return Qnil;

  VALUE MAYBE_UNUSED(enc) = rb_iv_get(self, "@encoding");
  return NOKOGIRI_STR_NEW2(prefix,
      RTEST(enc) ? StringValuePtr(enc) : NULL);
}

/*
 * call-seq:
 *   namespace_uri
 *
 * Get the URI defining the namespace associated with the node
 */
static VALUE namespace_uri(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);
  const char * uri = (const char *)xmlTextReaderConstNamespaceUri(reader);
  if(uri == NULL) return Qnil;

  VALUE MAYBE_UNUSED(enc) = rb_iv_get(self, "@encoding");
  return NOKOGIRI_STR_NEW2(uri,
      RTEST(enc) ? StringValuePtr(enc) : NULL);
}

/*
 * call-seq:
 *   local_name
 *
 * Get the local name of the node
 */
static VALUE local_name(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);
  const char * name = (const char *)xmlTextReaderConstLocalName(reader);
  if(name == NULL) return Qnil;

  VALUE MAYBE_UNUSED(enc) = rb_iv_get(self, "@encoding");
  return NOKOGIRI_STR_NEW2(name,
      RTEST(enc) ? StringValuePtr(enc) : NULL);
}

/*
 * call-seq:
 *   name
 *
 * Get the name of the node
 */
static VALUE name(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);
  const char * name = (const char *)xmlTextReaderConstName(reader);
  if(name == NULL) return Qnil;

  VALUE MAYBE_UNUSED(enc) = rb_iv_get(self, "@encoding");
  return NOKOGIRI_STR_NEW2(name,
      RTEST(enc) ? StringValuePtr(enc) : NULL);
}

/*
 * call-seq:
 *   state
 *
 * Get the state of the reader
 */
static VALUE state(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);
  return INT2NUM(xmlTextReaderReadState(reader));
}

/*
 * call-seq:
 *   read
 *
 * Move the Reader forward through the XML document.
 */
static VALUE read_more(VALUE self)
{
  xmlTextReaderPtr reader;
  Data_Get_Struct(self, xmlTextReader, reader);

  VALUE error_list = rb_funcall(self, rb_intern("errors"), 0);

  xmlSetStructuredErrorFunc((void *)error_list, Nokogiri_error_array_pusher);
  int ret = xmlTextReaderRead(reader);
  xmlSetStructuredErrorFunc(NULL, NULL);

  if(ret == 1) return self;
  if(ret == 0) return Qnil;

  xmlErrorPtr error = xmlGetLastError();
  if(error)
    rb_funcall(rb_mKernel, rb_intern("raise"), 1,
        Nokogiri_wrap_xml_syntax_error((VALUE)NULL, error)
    );
  else
    rb_raise(rb_eRuntimeError, "Error pulling: %d", ret);

  return Qnil;
}

/*
 * call-seq:
 *   from_memory(string, url = nil, encoding = nil, options = 0)
 *
 * Create a new reader that parses +string+
 */
static VALUE from_memory(int argc, VALUE *argv, VALUE klass)
{
  VALUE rb_buffer, rb_url, encoding, rb_options;

  const char * c_url      = NULL;
  const char * c_encoding = NULL;
  int c_options           = 0; 

  rb_scan_args(argc, argv, "13", &rb_buffer, &rb_url, &encoding, &rb_options);

  if (!RTEST(rb_buffer)) rb_raise(rb_eArgError, "string cannot be nil");
  if (RTEST(rb_url)) c_url = StringValuePtr(rb_url);
  if (RTEST(encoding)) c_encoding = StringValuePtr(encoding);
  if (RTEST(rb_options)) c_options = NUM2INT(rb_options);

  xmlTextReaderPtr reader = xmlReaderForMemory(
      StringValuePtr(rb_buffer),
      RSTRING_LEN(rb_buffer),
      c_url,
      c_encoding,
      c_options
  );

  if(reader == NULL) {
    xmlFreeTextReader(reader);
    rb_raise(rb_eRuntimeError, "couldn't create a parser");
  }

  VALUE rb_reader = Data_Wrap_Struct(klass, NULL, dealloc, reader);
  rb_funcall(rb_reader, rb_intern("initialize"), 3, rb_buffer, rb_url, encoding);

  return rb_reader;
}

/*
 * call-seq:
 *   from_io(io, url = nil, encoding = nil, options = 0)
 *
 * Create a new reader that parses +io+
 */
static VALUE from_io(int argc, VALUE *argv, VALUE klass)
{
  VALUE rb_io, rb_url, encoding, rb_options;

  const char * c_url      = NULL;
  const char * c_encoding = NULL;
  int c_options           = 0; 

  rb_scan_args(argc, argv, "13", &rb_io, &rb_url, &encoding, &rb_options);

  if (!RTEST(rb_io)) rb_raise(rb_eArgError, "io cannot be nil");
  if (RTEST(rb_url)) c_url = StringValuePtr(rb_url);
  if (RTEST(encoding)) c_encoding = StringValuePtr(encoding);
  if (RTEST(rb_options)) c_options = NUM2INT(rb_options);

  xmlTextReaderPtr reader = xmlReaderForIO(
      (xmlInputReadCallback)io_read_callback,
      (xmlInputCloseCallback)io_close_callback,
      (void *)rb_io,
      c_url,
      c_encoding,
      c_options
  );

  if(reader == NULL) {
    xmlFreeTextReader(reader);
    rb_raise(rb_eRuntimeError, "couldn't create a parser");
  }

  VALUE rb_reader = Data_Wrap_Struct(klass, NULL, dealloc, reader);
  rb_funcall(rb_reader, rb_intern("initialize"), 3, rb_io, rb_url, encoding);

  return rb_reader;
}

VALUE cNokogiriXmlReader;

void init_xml_reader()
{
  VALUE module = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(module, "XML");

  /*
   * The Reader parser allows you to effectively pull parse an XML document.
   * Once instantiated, call Nokogiri::XML::Reader#each to iterate over each
   * node.  Note that you may only iterate over the document once!
   */
  VALUE klass = rb_define_class_under(xml, "Reader", rb_cObject);

  cNokogiriXmlReader = klass;

  rb_define_singleton_method(klass, "from_memory", from_memory, -1);
  rb_define_singleton_method(klass, "from_io", from_io, -1);

  rb_define_method(klass, "read", read_more, 0);
  rb_define_method(klass, "state", state, 0);
  rb_define_method(klass, "name", name, 0);
  rb_define_method(klass, "local_name", local_name, 0);
  rb_define_method(klass, "namespace_uri", namespace_uri, 0);
  rb_define_method(klass, "prefix", prefix, 0);
  rb_define_method(klass, "value", value, 0);
  rb_define_method(klass, "lang", lang, 0);
  rb_define_method(klass, "xml_version", xml_version, 0);
  rb_define_method(klass, "depth", depth, 0);
  rb_define_method(klass, "attribute_count", attribute_count, 0);
  rb_define_method(klass, "attribute", reader_attribute, 1);
  rb_define_method(klass, "namespaces", namespaces, 0);
  rb_define_method(klass, "attribute_at", attribute_at, 1);
  rb_define_method(klass, "attribute_nodes", attribute_nodes, 0);
  rb_define_method(klass, "attributes?", attributes_eh, 0);
  rb_define_method(klass, "value?", value_eh, 0);
  rb_define_method(klass, "default?", default_eh, 0);
}
