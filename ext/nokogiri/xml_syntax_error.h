#ifndef NOKOGIRI_XML_SYNTAX_ERROR
#define NOKOGIRI_XML_SYNTAX_ERROR

#include <nokogiri.h>

void init_xml_syntax_error();
void Nokogiri_install_error_catcher(VALUE list);
void Nokogiri_remove_error_catcher();
VALUE Nokogiri_wrap_xml_syntax_error(VALUE klass, xmlErrorPtr error);
void Nokogiri_error_array_pusher(void * ctx, xmlErrorPtr error);
NORETURN(void Nokogiri_error_raise(void * ctx, xmlErrorPtr error));

extern VALUE cNokogiriXmlSyntaxError;
#endif

