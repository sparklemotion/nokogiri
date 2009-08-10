#ifndef NOKOGIRI_XML_SAX_PARSER
#define NOKOGIRI_XML_SAX_PARSER

#include <nokogiri.h>

void init_xml_sax_parser();

extern VALUE cNokogiriXmlSaxParser ;

typedef struct _nokogiriSAXTuple {
  xmlParserCtxtPtr  ctxt;
  VALUE             self;
} nokogiriSAXTuple;

typedef nokogiriSAXTuple * nokogiriSAXTuplePtr;

#define NOKOGIRI_SAX_SELF(_ctxt) \
  ({ \
    nokogiriSAXTuplePtr _tuple = (nokogiriSAXTuplePtr)(_ctxt); \
    _tuple->self; \
  })

#define NOKOGIRI_SAX_CTXT(_ctxt) \
  ({ \
    nokogiriSAXTuplePtr _tuple = (nokogiriSAXTuplePtr)(_ctxt); \
    _tuple->ctxt; \
  })

#define NOKOGIRI_SAX_TUPLE_NEW(_ctxt, _self) \
  ({ \
    nokogiriSAXTuplePtr _tuple = malloc(sizeof(nokogiriSAXTuple)); \
    _tuple->self = _self; \
    _tuple->ctxt = _ctxt; \
    _tuple; \
  })

#define NOKOGIRI_SAX_TUPLE_DESTROY(_tuple) \
  ({ \
    free(_tuple); \
  })

#endif

