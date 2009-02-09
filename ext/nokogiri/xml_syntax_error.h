#ifndef NOKOGIRI_XML_SYNTAX_ERROR
#define NOKOGIRI_XML_SYNTAX_ERROR

#include <native.h>

void init_xml_syntax_error();
VALUE Nokogiri_wrap_xml_syntax_error(VALUE klass, xmlErrorPtr error);
void Nokogiri_error_array_pusher(void * ctx, xmlErrorPtr error);

extern VALUE cNokogiriXmlSyntaxError;
#endif

