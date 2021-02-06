#ifndef NOKOGIRI_NATIVE
#define NOKOGIRI_NATIVE

#if _MSC_VER
#  ifndef WIN32_LEAN_AND_MEAN
#    define WIN32_LEAN_AND_MEAN
#  endif /* WIN32_LEAN_AND_MEAN */

#  ifndef WIN32
#    define WIN32
#  endif /* WIN32 */

#  include <winsock2.h>
#  include <ws2tcpip.h>
#  include <windows.h>
#endif

#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdarg.h>
#include <stdio.h>

#include <ruby.h>
#include <ruby/st.h>
#include <ruby/encoding.h>
#include <ruby/util.h>

#include <libxml/parser.h>
#include <libxml/tree.h>
#include <libxml/entities.h>
#include <libxml/xpath.h>
#include <libxml/xmlreader.h>
#include <libxml/xmlsave.h>
#include <libxml/xmlschemas.h>
#include <libxml/HTMLparser.h>
#include <libxml/HTMLtree.h>
#include <libxml/relaxng.h>
#include <libxml/xinclude.h>
#include <libxml/c14n.h>
#include <libxml/parserInternals.h>
#include <libxml/xpathInternals.h>

#include <libxslt/extensions.h>
#include <libxslt/xsltconfig.h>
#include <libxslt/xsltutils.h>
#include <libxslt/transform.h>
#include <libxslt/xsltInternals.h>

#include <libexslt/exslt.h>

/* libxml2_backwards_compat.c */
#ifndef HAVE_XMLFIRSTELEMENTCHILD
xmlNodePtr xmlFirstElementChild(xmlNodePtr parent);
xmlNodePtr xmlNextElementSibling(xmlNodePtr node);
xmlNodePtr xmlLastElementChild(xmlNodePtr parent);
#endif

#define XMLNS_PREFIX "xmlns"
#define XMLNS_PREFIX_LEN 6 /* including either colon or \0 */

#define NOKOGIRI_STR_NEW2(str) NOKOGIRI_STR_NEW(str, strlen((const char *)(str)))
#define NOKOGIRI_STR_NEW(str, len) rb_external_str_new_with_enc((const char *)(str), (long)(len), rb_utf8_encoding())
#define RBSTR_OR_QNIL(_str) (_str ? NOKOGIRI_STR_NEW2(_str) : Qnil)

#ifdef DEBUG
#  define NOKOGIRI_DEBUG_START(p) if (getenv("NOKOGIRI_NO_FREE")) return ; if (getenv("NOKOGIRI_DEBUG")) fprintf(stderr,"nokogiri: %s:%d %p start\n", __FILE__, __LINE__, p);
#  define NOKOGIRI_DEBUG_END(p) if (getenv("NOKOGIRI_DEBUG")) fprintf(stderr,"nokogiri: %s:%d %p end\n", __FILE__, __LINE__, p);
#else
#  define NOKOGIRI_DEBUG_START(p)
#  define NOKOGIRI_DEBUG_END(p)
#endif

#ifndef NORETURN
#  if defined(__GNUC__)
#    define NORETURN(name) __attribute__((noreturn)) name
#  else
#    define NORETURN(name) name
#  endif
#endif

extern VALUE mNokogiri ;
extern VALUE mNokogiriHtml ;
extern VALUE mNokogiriHtmlSax ;
extern VALUE mNokogiriXml ;
extern VALUE mNokogiriXmlSax ;
extern VALUE mNokogiriXslt ;

extern VALUE cNokogiriSyntaxError;
extern VALUE cNokogiriXmlAttr;
extern VALUE cNokogiriXmlAttributeDecl;
extern VALUE cNokogiriXmlCData;
extern VALUE cNokogiriXmlCharacterData;
extern VALUE cNokogiriXmlComment;
extern VALUE cNokogiriXmlDocument ;
extern VALUE cNokogiriXmlDocumentFragment;
extern VALUE cNokogiriXmlDtd;
extern VALUE cNokogiriXmlElement ;
extern VALUE cNokogiriXmlElementContent;
extern VALUE cNokogiriXmlElementDecl;
extern VALUE cNokogiriXmlEntityDecl;
extern VALUE cNokogiriXmlEntityReference;
extern VALUE cNokogiriXmlNamespace ;
extern VALUE cNokogiriXmlNode ;
extern VALUE cNokogiriXmlNodeSet ;
extern VALUE cNokogiriXmlProcessingInstruction;
extern VALUE cNokogiriXmlReader;
extern VALUE cNokogiriXmlRelaxNG;
extern VALUE cNokogiriXmlSaxParser ;
extern VALUE cNokogiriXmlSaxParserContext;
extern VALUE cNokogiriXmlSaxPushParser ;
extern VALUE cNokogiriXmlSchema;
extern VALUE cNokogiriXmlSyntaxError;
extern VALUE cNokogiriXmlText ;
extern VALUE cNokogiriXmlXpathContext;
extern VALUE cNokogiriXmlXpathSyntaxError;
extern VALUE cNokogiriXsltStylesheet ;

extern VALUE cNokogiriHtmlDocument ;
extern VALUE cNokogiriHtmlSaxPushParser ;
extern VALUE cNokogiriHtmlElementDescription ;
extern VALUE cNokogiriHtmlSaxParserContext;

typedef struct _nokogiriTuple {
  VALUE         doc;
  st_table     *unlinkedNodes;
  VALUE         node_cache;
} nokogiriTuple;
typedef nokogiriTuple *nokogiriTuplePtr;

typedef struct _nokogiriSAXTuple {
  xmlParserCtxtPtr  ctxt;
  VALUE             self;
} nokogiriSAXTuple;
typedef nokogiriSAXTuple *nokogiriSAXTuplePtr;

typedef struct _libxmlStructuredErrorHandlerState {
  void *user_data;
  xmlStructuredErrorFunc handler;
} libxmlStructuredErrorHandlerState ;

typedef struct _nokogiriXsltStylesheetTuple {
  xsltStylesheetPtr ss;
  VALUE func_instances;
} nokogiriXsltStylesheetTuple;

int vasprintf(char **strp, const char *fmt, va_list ap);
void noko_xml_document_pin_node(xmlNodePtr);
void noko_xml_document_pin_namespace(xmlNsPtr, xmlDocPtr);

int noko_io_read(void *ctx, char *buffer, int len);
int noko_io_write(void *ctx, char *buffer, int len);
int noko_io_close(void *ctx);

VALUE noko_xml_document_wrap_with_init_args(VALUE klass, xmlDocPtr doc, int argc, VALUE *argv);
VALUE noko_xml_document_wrap(VALUE klass, xmlDocPtr doc);
VALUE Nokogiri_wrap_xml_document(VALUE klass, xmlDocPtr doc); /* deprecated. use noko_xml_document_wrap() instead. */

VALUE Nokogiri_wrap_xml_namespace(xmlDocPtr doc, xmlNsPtr node);
VALUE Nokogiri_xml_namespace__wrap_xpath_query_copy(xmlNsPtr node);

VALUE Nokogiri_wrap_xml_node(VALUE klass, xmlNodePtr node) ;
VALUE Nokogiri_wrap_xml_node_set(xmlNodeSetPtr node_set, VALUE document) ;
VALUE Nokogiri_wrap_xml_node_set_node(xmlNodePtr node, VALUE node_set) ;
VALUE Nokogiri_wrap_xml_node_set_namespace(xmlNsPtr node, VALUE node_set) ;

VALUE Nokogiri_wrap_element_content(VALUE doc, xmlElementContentPtr element);

void Nokogiri_xml_node_properties(xmlNodePtr node, VALUE attr_hash) ;

#define DOC_RUBY_OBJECT_TEST(x) ((nokogiriTuplePtr)(x->_private))
#define DOC_RUBY_OBJECT(x) (((nokogiriTuplePtr)(x->_private))->doc)
#define DOC_UNLINKED_NODE_HASH(x) (((nokogiriTuplePtr)(x->_private))->unlinkedNodes)
#define DOC_NODE_CACHE(x) (((nokogiriTuplePtr)(x->_private))->node_cache)
#define NOKOGIRI_NAMESPACE_EH(node) ((node)->type == XML_NAMESPACE_DECL)

#define NOKOGIRI_SAX_SELF(_ctxt) ((nokogiriSAXTuplePtr)(_ctxt))->self
#define NOKOGIRI_SAX_CTXT(_ctxt) ((nokogiriSAXTuplePtr)(_ctxt))->ctxt
#define NOKOGIRI_SAX_TUPLE_NEW(_ctxt, _self) nokogiri_sax_tuple_new(_ctxt, _self)
#define NOKOGIRI_SAX_TUPLE_DESTROY(_tuple) free(_tuple)

void Nokogiri_structured_error_func_save(libxmlStructuredErrorHandlerState *handler_state);
void Nokogiri_structured_error_func_save_and_set(libxmlStructuredErrorHandlerState *handler_state, void *user_data,
    xmlStructuredErrorFunc handler);
void Nokogiri_structured_error_func_restore(libxmlStructuredErrorHandlerState *handler_state);
VALUE Nokogiri_wrap_xml_syntax_error(xmlErrorPtr error);
void Nokogiri_error_array_pusher(void *ctx, xmlErrorPtr error);
NORETURN(void Nokogiri_error_raise(void *ctx, xmlErrorPtr error));
void Nokogiri_marshal_xpath_funcall_and_return_values(xmlXPathParserContextPtr ctx, int nargs, VALUE handler,
    const char *function_name) ;

static inline
nokogiriSAXTuplePtr
nokogiri_sax_tuple_new(xmlParserCtxtPtr ctxt, VALUE self)
{
  nokogiriSAXTuplePtr tuple = malloc(sizeof(nokogiriSAXTuple));
  tuple->self = self;
  tuple->ctxt = ctxt;
  return tuple;
}

#endif /* NOKOGIRI_NATIVE */
