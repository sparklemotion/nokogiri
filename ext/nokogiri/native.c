#include <native.h>

VALUE mNokogiri ;
VALUE mNokogiriXml ;
VALUE mNokogiriHtml ;
VALUE mNokogiriXslt ;
VALUE mNokogiriXmlSax ;
VALUE mNokogiriHtmlSax ;

void Init_native()
{
  xmlMemSetup(
      (xmlFreeFunc)ruby_xfree,
      (xmlMallocFunc)ruby_xmalloc,
      (xmlReallocFunc)ruby_xrealloc,
      strdup
  );

  mNokogiri         = rb_define_module("Nokogiri");
  mNokogiriXml      = rb_define_module_under(mNokogiri, "XML");
  mNokogiriHtml     = rb_define_module_under(mNokogiri, "HTML");
  mNokogiriXslt     = rb_define_module_under(mNokogiri, "XSLT");
  mNokogiriXmlSax   = rb_define_module_under(mNokogiriXml, "SAX");
  mNokogiriHtmlSax  = rb_define_module_under(mNokogiriHtml, "SAX");

  rb_const_set( mNokogiri,
                rb_intern("LIBXML_VERSION"),
                NOKOGIRI_STR_NEW2(LIBXML_DOTTED_VERSION, "UTF-8")
              );

  init_xml_document();
  init_html_document();
  init_xml_node();
  init_xml_document_fragment();
  init_xml_text();
  init_xml_cdata();
  init_xml_processing_instruction();
  init_xml_attr();
  init_xml_entity_reference();
  init_xml_comment();
  init_xml_node_set();
  init_xml_xpath_context();
  init_xml_xpath();
  init_xml_sax_parser();
  init_xml_sax_push_parser();
  init_xml_reader();
  init_xml_dtd();
  init_html_sax_parser();
  init_xslt_stylesheet();
  init_xml_syntax_error();
}
