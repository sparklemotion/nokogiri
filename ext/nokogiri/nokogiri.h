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


/* nokogiri.c */
extern VALUE mNokogiri ;
extern VALUE mNokogiriXml ;
extern VALUE mNokogiriXmlSax ;
extern VALUE mNokogiriHtml ;
extern VALUE mNokogiriHtmlSax ;
extern VALUE mNokogiriXslt ;

int vasprintf(char **strp, const char *fmt, va_list ap);
void nokogiri_root_node(xmlNodePtr);
void nokogiri_root_nsdef(xmlNsPtr, xmlDocPtr);


extern VALUE cNokogiriXmlAttr;
void init_xml_attr();

extern VALUE cNokogiriXmlAttributeDecl;
void init_xml_attribute_decl();

extern VALUE cNokogiriXmlCData;
void init_xml_cdata();

extern VALUE cNokogiriXmlComment;
void init_xml_comment();


/* xml_document.c */
typedef struct _nokogiriTuple {
  VALUE         doc;
  st_table     *unlinkedNodes;
  VALUE         node_cache;
} nokogiriTuple;
typedef nokogiriTuple * nokogiriTuplePtr;

extern VALUE cNokogiriXmlDocument ;
void init_xml_document();
VALUE nokogiri_xml_document_wrap_with_init_args(VALUE klass, xmlDocPtr doc, int argc, VALUE *argv);
VALUE nokogiri_xml_document_wrap(VALUE klass, xmlDocPtr doc);

#define DOC_RUBY_OBJECT_TEST(x) ((nokogiriTuplePtr)(x->_private))
#define DOC_RUBY_OBJECT(x) (((nokogiriTuplePtr)(x->_private))->doc)
#define DOC_UNLINKED_NODE_HASH(x) (((nokogiriTuplePtr)(x->_private))->unlinkedNodes)
#define DOC_NODE_CACHE(x) (((nokogiriTuplePtr)(x->_private))->node_cache)

/* deprecated. use nokogiri_xml_document_wrap() instead. */
VALUE Nokogiri_wrap_xml_document(VALUE klass, xmlDocPtr doc);


extern VALUE cNokogiriXmlDocumentFragment;
void init_xml_document_fragment();

extern VALUE cNokogiriXmlDtd;
void init_xml_dtd();

extern VALUE cNokogiriXmlElementContent;
VALUE Nokogiri_wrap_element_content(VALUE doc, xmlElementContentPtr element);
void init_xml_element_content();

extern VALUE cNokogiriXmlElementDecl;
void init_xml_element_decl();

void init_xml_encoding_handler();

extern VALUE cNokogiriXmlEntityDecl;
void init_xml_entity_decl();

extern VALUE cNokogiriXmlEntityReference;
void init_xml_entity_reference();

/* xml_io.c */
int io_read_callback(void * ctx, char * buffer, int len);
int io_write_callback(void * ctx, char * buffer, int len);
int io_close_callback(void * ctx);
void init_nokogiri_io();

/* xml_namespace.c */
extern VALUE cNokogiriXmlNamespace ;
void init_xml_namespace();
VALUE Nokogiri_wrap_xml_namespace(xmlDocPtr doc, xmlNsPtr node);
VALUE Nokogiri_xml_namespace__wrap_xpath_query_copy(xmlNsPtr node);
#define NOKOGIRI_NAMESPACE_EH(node) ((node)->type == XML_NAMESPACE_DECL)

/* xml_node.c */
extern VALUE cNokogiriXmlNode ;
extern VALUE cNokogiriXmlElement ;
void init_xml_node();
VALUE Nokogiri_wrap_xml_node(VALUE klass, xmlNodePtr node) ;
void Nokogiri_xml_node_properties(xmlNodePtr node, VALUE attr_hash) ;

/* xml_node_set.c */
extern VALUE cNokogiriXmlNodeSet ;
void init_xml_node_set();
VALUE Nokogiri_wrap_xml_node_set(xmlNodeSetPtr node_set, VALUE document) ;
VALUE Nokogiri_wrap_xml_node_set_node(xmlNodePtr node, VALUE node_set) ;
VALUE Nokogiri_wrap_xml_node_set_namespace(xmlNsPtr node, VALUE node_set) ;

extern VALUE cNokogiriXmlProcessingInstruction;
void init_xml_processing_instruction();

extern VALUE cNokogiriXmlReader;
void init_xml_reader();

extern VALUE cNokogiriXmlRelaxNG;
void init_xml_relax_ng();


/* xml_sax_parser.c */
extern VALUE cNokogiriXmlSaxParser ;
void init_xml_sax_parser();

typedef struct _nokogiriSAXTuple {
  xmlParserCtxtPtr  ctxt;
  VALUE             self;
} nokogiriSAXTuple;
typedef nokogiriSAXTuple * nokogiriSAXTuplePtr;

static inline
nokogiriSAXTuplePtr
nokogiri_sax_tuple_new(xmlParserCtxtPtr ctxt, VALUE self)
{
  nokogiriSAXTuplePtr tuple = malloc(sizeof(nokogiriSAXTuple));
  tuple->self = self;
  tuple->ctxt = ctxt;
  return tuple;
}

#define NOKOGIRI_SAX_SELF(_ctxt) ((nokogiriSAXTuplePtr)(_ctxt))->self
#define NOKOGIRI_SAX_CTXT(_ctxt) ((nokogiriSAXTuplePtr)(_ctxt))->ctxt
#define NOKOGIRI_SAX_TUPLE_NEW(_ctxt, _self) nokogiri_sax_tuple_new(_ctxt, _self)
#define NOKOGIRI_SAX_TUPLE_DESTROY(_tuple) free(_tuple)


extern VALUE cNokogiriXmlSaxParserContext;
void init_xml_sax_parser_context();

extern VALUE cNokogiriXmlSaxPushParser ;
void init_xml_sax_push_parser();

extern VALUE cNokogiriXmlSchema;
void init_xml_schema();


/* xml_syntax_error.c */
extern VALUE cNokogiriXmlSyntaxError;
void init_xml_syntax_error();

typedef struct _libxmlStructuredErrorHandlerState {
  void *user_data;
  xmlStructuredErrorFunc handler;
} libxmlStructuredErrorHandlerState ;

void Nokogiri_structured_error_func_save(libxmlStructuredErrorHandlerState *handler_state);
void Nokogiri_structured_error_func_save_and_set(libxmlStructuredErrorHandlerState *handler_state,
                                                 void *user_data,
                                                 xmlStructuredErrorFunc handler);
void Nokogiri_structured_error_func_restore(libxmlStructuredErrorHandlerState *handler_state);

VALUE Nokogiri_wrap_xml_syntax_error(xmlErrorPtr error);
void Nokogiri_error_array_pusher(void *ctx, xmlErrorPtr error);
NORETURN(void Nokogiri_error_raise(void *ctx, xmlErrorPtr error));


extern VALUE cNokogiriXmlText ;
void init_xml_text();

/* xml_xpath_context.c */
extern VALUE cNokogiriXmlXpathContext;
void init_xml_xpath_context();
void Nokogiri_marshal_xpath_funcall_and_return_values(xmlXPathParserContextPtr ctx, int nargs, VALUE handler, const char* function_name) ;


extern VALUE cNokogiriXsltStylesheet ;
void init_xslt_stylesheet();

typedef struct _nokogiriXsltStylesheetTuple {
  xsltStylesheetPtr ss;
  VALUE func_instances;
} nokogiriXsltStylesheetTuple;


extern VALUE cNokogiriHtmlDocument ;
void init_html_document();


extern VALUE cNokogiriHtmlElementDescription ;
void init_html_element_description();

void init_html_entity_lookup();

extern VALUE cNokogiriHtmlSaxParserContext;
void init_html_sax_parser_context();

extern VALUE cNokogiriHtmlSaxPushParser ;
void init_html_sax_push_parser();


/* test_global_handlers.h */
void init_test_global_handlers();

#endif /* NOKOGIRI_NATIVE */
