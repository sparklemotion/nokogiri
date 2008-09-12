#include <xslt_stylesheet.h>

#include "libxslt/xsltInternals.h"
#include "libxslt/xsltutils.h"
#include "libxslt/transform.h"

static void dealloc(xsltStylesheetPtr doc)
{
  /* TODO: I get segfaults when I free this. Figure out what's whalloping the heap.
*** glibc detected *** ruby: free(): invalid pointer: 0x08340d00 ***
======= Backtrace: =========
/lib/tls/i686/cmov/libc.so.6[0xb7d42a85]
/lib/tls/i686/cmov/libc.so.6(cfree+0x90)[0xb7d464f0]
/usr/lib/libxml2.so(xmlFreeNs+0x33)[0xb7a70ef3]
/usr/lib/libxml2.so(xmlFreeNsList+0x1a)[0xb7a70f3a]
/usr/lib/libxml2.so(xmlFreeNodeList+0xef)[0xb7a7818f]
/usr/lib/libxml2.so(xmlFreeDoc+0xbc)[0xb7a77f7c]
/usr/lib/libxslt.so.1(xsltFreeStylesheet+0x32b)[0xb79f42db]
/home/mike/code/nokogiri/ext/nokogiri/native.so[0xb7f6e9f4]
/usr/lib/libruby1.8.so.1.8(rb_gc_call_finalizer_at_exit+0xa7)[0xb7eddd37]
  */     

//  xsltFreeStylesheet(doc); // commented out for now.
}

static VALUE parse_stylesheet_doc(VALUE klass, VALUE xmldocobj)
{
    xmlDocPtr xml ;
    xsltStylesheetPtr ss ;
    Data_Get_Struct(xmldocobj, xmlDoc, xml);
    ss = xsltParseStylesheetDoc(xml);
    return Data_Wrap_Struct(klass, NULL, dealloc, ss);
}


static VALUE serialize(VALUE self, VALUE xmlobj)
{
    xmlDocPtr xml ;
    xsltStylesheetPtr ss ;
    xmlChar* doc_ptr ;
    int doc_len ;
    VALUE rval ;

    Data_Get_Struct(xmlobj, xmlDoc, xml);
    Data_Get_Struct(self, xsltStylesheet, ss);
    xsltSaveResultToString(&doc_ptr, &doc_len, xml, ss);
    rval = rb_str_new((char*)doc_ptr, doc_len);
    free(doc_ptr);
    return rval ;
}


static VALUE apply_to(VALUE self, VALUE xmldoc, VALUE paramobj)
{
    xmlDocPtr xml ;
    xmlDocPtr result ;
    xsltStylesheetPtr ss ;
    const char** params ;
    int param_len, j ;
    VALUE resultobj ;

    Data_Get_Struct(xmldoc, xmlDoc, xml);
    Data_Get_Struct(self, xsltStylesheet, ss);

    param_len = RARRAY_LEN(paramobj);
    params = calloc((size_t)param_len+1, sizeof(char*));
    for (j = 0 ; j < param_len ; j++) {
        params[j] = RSTRING(rb_ary_entry(paramobj, j))->ptr ;
    }
    params[param_len] = 0 ;

    result = xsltApplyStylesheet(ss, xml, params);
    free(params);
    resultobj = Nokogiri_wrap_xml_document(result) ;
    return rb_funcall(self, rb_intern("serialize"), 1, resultobj);
}

void init_xslt_stylesheet()
{
  VALUE m_nokogiri  = rb_const_get(rb_cObject, rb_intern("Nokogiri"));
  VALUE m_xml       = rb_const_get(m_nokogiri, rb_intern("XSLT"));
  VALUE klass       = rb_const_get(m_xml, rb_intern("Stylesheet"));
    
  rb_define_singleton_method(klass, "parse_stylesheet_doc", parse_stylesheet_doc, 1);
  rb_define_method(klass, "serialize", serialize, 1);
  rb_define_method(klass, "apply_to", apply_to, 2);
}
