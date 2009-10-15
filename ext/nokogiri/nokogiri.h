#ifndef NOKOGIRI_NATIVE
#define NOKOGIRI_NATIVE

#include <stdlib.h>
#include <assert.h>
#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxml/xmlreader.h>
#include <libxml/xmlsave.h>
#include <libxml/xmlschemas.h>
#include <libxml/HTMLparser.h>
#include <libxml/HTMLtree.h>
#include <libxml/relaxng.h>
#include <ruby.h>

#ifdef USE_INCLUDED_VASPRINTF
int vasprintf (char **strp, const char *fmt, va_list ap);
#else

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#  include <stdio.h>

#endif

int is_2_6_16(void) ;

#ifndef UNUSED
# if defined(__GNUC__)
#  define MAYBE_UNUSED(name) name __attribute__((unused))
#  define UNUSED(name) MAYBE_UNUSED(UNUSED_ ## name)
# else
#  define MAYBE_UNUSED(name) name
#  define UNUSED(name) name
# endif
#endif

#ifdef HAVE_RUBY_ENCODING_H

#include <ruby/encoding.h>

#define NOKOGIRI_STR_NEW2(str) \
  ({ \
    VALUE _string = rb_str_new2((const char *)str); \
    int _enc = rb_enc_find_index("UTF-8"); \
    rb_enc_associate_index(_string, _enc); \
    _string; \
  })

#define NOKOGIRI_STR_NEW(str, len) \
  ({ \
    VALUE _string = rb_str_new((const char *)str, (long)len); \
    int _enc = rb_enc_find_index("UTF-8"); \
    rb_enc_associate_index(_string, _enc); \
    _string; \
  })

#else

#define NOKOGIRI_STR_NEW2(str) \
  rb_str_new2((const char *)str)

#define NOKOGIRI_STR_NEW(str, len) \
  rb_str_new((const char *)str, (long)len)
#endif

#include <xml_io.h>
#include <xml_document.h>
#include <html_entity_lookup.h>
#include <html_document.h>
#include <xml_node.h>
#include <xml_text.h>
#include <xml_cdata.h>
#include <xml_attr.h>
#include <xml_processing_instruction.h>
#include <xml_entity_reference.h>
#include <xml_document_fragment.h>
#include <xml_comment.h>
#include <xml_node_set.h>
#include <xml_xpath.h>
#include <xml_dtd.h>
#include <xml_attribute_decl.h>
#include <xml_element_decl.h>
#include <xml_entity_decl.h>
#include <xml_xpath_context.h>
#include <xml_element_content.h>
#include <xml_sax_parser_context.h>
#include <xml_sax_parser.h>
#include <xml_sax_push_parser.h>
#include <xml_reader.h>
#include <html_sax_parser_context.h>
#include <xslt_stylesheet.h>
#include <xml_syntax_error.h>
#include <xml_schema.h>
#include <xml_relax_ng.h>
#include <html_element_description.h>
#include <xml_namespace.h>

extern VALUE mNokogiri ;
extern VALUE mNokogiriXml ;
extern VALUE mNokogiriXmlSax ;
extern VALUE mNokogiriHtml ;
extern VALUE mNokogiriHtmlSax ;
extern VALUE mNokogiriXslt ;

#define NOKOGIRI_ROOT_NODE(_node) \
  ({ \
    nokogiriTuplePtr tuple = (nokogiriTuplePtr)(_node->doc->_private);       \
    st_insert(tuple->unlinkedNodes, (st_data_t)_node, (st_data_t)_node);     \
    _node; \
  })

#ifdef DEBUG

#define NOKOGIRI_DEBUG_START(p) if (getenv("NOKOGIRI_NO_FREE")) return ; if (getenv("NOKOGIRI_DEBUG")) fprintf(stderr,"nokogiri: %s:%d %p start\n", __FILE__, __LINE__, p);
#define NOKOGIRI_DEBUG_END(p) if (getenv("NOKOGIRI_DEBUG")) fprintf(stderr,"nokogiri: %s:%d %p end\n", __FILE__, __LINE__, p);

#else

#define NOKOGIRI_DEBUG_START(p)
#define NOKOGIRI_DEBUG_END(p)

#ifndef RSTRING_PTR
#define RSTRING_PTR(s) (RSTRING(s)->ptr)
#endif

#ifndef RSTRING_LEN
#define RSTRING_LEN(s) (RSTRING(s)->len)
#endif

#ifndef RARRAY_PTR
#define RARRAY_PTR(a) RARRAY(a)->ptr
#endif

#ifndef RARRAY_LEN
#define RARRAY_LEN(a) RARRAY(a)->len
#endif

#endif

#endif
