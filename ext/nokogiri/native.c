#include <native.h>

VALUE mNokogiri ;
VALUE mNokogiriXml ;
VALUE mNokogiriHtml ;
VALUE mNokogiriXslt ;
VALUE mNokogiriXmlSax ;
VALUE mNokogiriHtmlSax ;

void Init_native()
{
  mNokogiri = rb_const_get(rb_cObject, rb_intern("Nokogiri"));
  mNokogiriXml = rb_const_get(mNokogiri, rb_intern("XML"));
  mNokogiriHtml = rb_const_get(mNokogiri, rb_intern("HTML"));
  mNokogiriXslt = rb_const_get(mNokogiri, rb_intern("XSLT"));
  mNokogiriXmlSax = rb_const_get(mNokogiriXml, rb_intern("SAX"));
  mNokogiriHtmlSax = rb_const_get(mNokogiriHtml, rb_intern("SAX"));

  rb_const_set( mNokogiri,
                rb_intern("LIBXML_VERSION"),
                rb_str_new2(LIBXML_DOTTED_VERSION)
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
