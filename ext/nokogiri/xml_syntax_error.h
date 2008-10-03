#ifndef NOKOGIRI_XML_SYNTAX_ERROR
#define NOKOGIRI_XML_SYNTAX_ERROR

#include <native.h>

void init_xml_syntax_error();
void Nokogiri_error_handler(void * ctx, xmlErrorPtr error);

extern VALUE cNokogiriXmlSyntaxError;
#endif

