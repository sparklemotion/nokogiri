#ifndef NOKOGIRI_XML_NODE
#define NOKOGIRI_XML_NODE

#include <native.h>

void init_xml_node();
VALUE Nokogiri_wrap_xml_node(xmlNodePtr root);

#endif
