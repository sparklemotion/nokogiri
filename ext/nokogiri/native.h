#ifndef NOKOGIRI_NATIVE
#define NOKOGIRI_NATIVE

#include <stdlib.h>
#include <assert.h>
#include <ruby.h>
#include <libxml/parser.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxml/xmlreader.h>
#include <libxml/HTMLparser.h>
#include <libxml/HTMLtree.h>

#include <xml_io.h>
#include <xml_document.h>
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
#include <xml_xpath_context.h>
#include <xml_sax_parser.h>
#include <xml_sax_push_parser.h>
#include <xml_reader.h>
#include <html_sax_parser.h>
#include <xslt_stylesheet.h>
#include <xml_syntax_error.h>

extern VALUE mNokogiri ;
extern VALUE mNokogiriXml ;
extern VALUE mNokogiriXmlSax ;
extern VALUE mNokogiriHtml ;
extern VALUE mNokogiriHtmlSax ;
extern VALUE mNokogiriXslt ;

#ifdef DEBUG

#define NOKOGIRI_DEBUG_START(p) if (getenv("NOKOGIRI_NO_FREE")) return ; if (getenv("NOKOGIRI_DEBUG")) fprintf(stderr,"nokogiri: %s:%d %p start\n", __FILE__, __LINE__, p);
#define NOKOGIRI_DEBUG_END(p) if (getenv("NOKOGIRI_DEBUG")) fprintf(stderr,"nokogiri: %s:%d %p end\n", __FILE__, __LINE__, p);

#else

#define NOKOGIRI_DEBUG_START(p)
#define NOKOGIRI_DEBUG_END(p)

#endif

#endif
