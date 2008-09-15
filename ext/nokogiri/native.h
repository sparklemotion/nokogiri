#ifndef NOKOGIRI_NATIVE
#define NOKOGIRI_NATIVE

#include <stdlib.h>
#include <ruby.h>
#include <libxml/parser.h>
#include <libxml/xpath.h>
#include <libxml/HTMLparser.h>
#include <libxml/HTMLtree.h>

#include <xml_document.h>
#include <html_document.h>
#include <xml_node.h>
#include <xml_text.h>
#include <xml_node_set.h>
#include <xml_xpath.h>
#include <xslt_stylesheet.h>

extern VALUE mNokogiri ;
extern VALUE mNokogiriXml ;
extern VALUE mNokogiriXml ;
extern VALUE mNokogiriHtml ;
extern VALUE mNokogiriXslt ;

#endif
