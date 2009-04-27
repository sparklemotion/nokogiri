#ifndef NOKOGIRI_XML_DOCUMENT
#define NOKOGIRI_XML_DOCUMENT

#include <nokogiri.h>

struct _nokogiriTuple {
  xmlDocPtr     doc;
  xmlNodeSetPtr unlinkedNodes;
};
typedef struct _nokogiriTuple nokogiriTuple;
typedef nokogiriTuple * nokogiriTuplePtr;

void init_xml_document();
VALUE Nokogiri_wrap_xml_document(VALUE klass, xmlDocPtr doc);

#define DOC_RUBY_OBJECT_TEST(x) ((nokogiriTuplePtr)(x->_private))
#define DOC_RUBY_OBJECT(x) ((VALUE)((nokogiriTuplePtr)(x->_private))->doc)
#define DOC_UNLINKED_NODE_SET(x) ((xmlNodeSetPtr)((nokogiriTuplePtr)(x->_private))->unlinkedNodes)

extern VALUE cNokogiriXmlDocument ;
#endif
