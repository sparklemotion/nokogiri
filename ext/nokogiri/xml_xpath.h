#ifndef NOKOGIRI_XML_XPATH
#define NOKOGIRI_XML_XPATH

#include <nokogiri.h>

void init_xml_xpath();
VALUE Nokogiri_wrap_xml_xpath(xmlXPathObjectPtr xpath);

extern VALUE cNokogiriXmlXpath;
#endif

