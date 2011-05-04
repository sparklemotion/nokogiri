#include <xslt_stylesheet.h>

#include <libxslt/xsltInternals.h>
#include <libxslt/xsltutils.h>
#include <libxslt/transform.h>
#include <libexslt/exslt.h>

VALUE xslt;

int vasprintf (char **strp, const char *fmt, va_list ap);
void vasprintf_free (void *p);

static void dealloc(xsltStylesheetPtr doc)
{
    NOKOGIRI_DEBUG_START(doc);
    xsltFreeStylesheet(doc); /* commented out for now. */
    NOKOGIRI_DEBUG_END(doc);
}

NORETURN(static void xslt_generic_error_handler(void * ctx, const char *msg, ...));
static void xslt_generic_error_handler(void * ctx, const char *msg, ...)
{
  char * message;
  VALUE exception;

  va_list args;
  va_start(args, msg);
  vasprintf(&message, msg, args);
  va_end(args);

  exception = rb_exc_new2(rb_eRuntimeError, message);
  vasprintf_free(message);
  rb_exc_raise(exception);
}

/*
 * call-seq:
 *   parse_stylesheet_doc(document)
 *
 * Parse a stylesheet from +document+.
 */
static VALUE parse_stylesheet_doc(VALUE klass, VALUE xmldocobj)
{
    xmlDocPtr xml ;
    xsltStylesheetPtr ss ;
    Data_Get_Struct(xmldocobj, xmlDoc, xml);
    exsltRegisterAll();

    xsltSetGenericErrorFunc(NULL, xslt_generic_error_handler);

    ss = xsltParseStylesheetDoc(xmlCopyDoc(xml, 1)); /* 1 => recursive */

    xsltSetGenericErrorFunc(NULL, NULL);

    return Data_Wrap_Struct(klass, NULL, dealloc, ss);
}


/*
 * call-seq:
 *   serialize(document)
 *
 * Serialize +document+ to an xml string.
 */
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
    rval = NOKOGIRI_STR_NEW(doc_ptr, doc_len);
    xmlFree(doc_ptr);
    return rval ;
}

/*
 *  call-seq:
 *    transform(document, params = [])
 *
 *  Apply an XSLT stylesheet to an XML::Document.
 *  +params+ is an array of strings used as XSLT parameters.
 *  returns Nokogiri::XML::Document
 *
 *  Example:
 * 
 *    doc   = Nokogiri::XML(File.read(ARGV[0]))
 *    xslt  = Nokogiri::XSLT(File.read(ARGV[1]))
 *    puts xslt.transform(doc, ['key', 'value'])
 *
 */
static VALUE transform(int argc, VALUE* argv, VALUE self)
{
    VALUE xmldoc, paramobj ;
    xmlDocPtr xml ;
    xmlDocPtr result ;
    xsltStylesheetPtr ss ;
    const char** params ;
    long param_len, j ;

    rb_scan_args(argc, argv, "11", &xmldoc, &paramobj);
    if (NIL_P(paramobj)) { paramobj = rb_ary_new2(0L) ; }
    if (!rb_obj_is_kind_of(xmldoc, cNokogiriXmlDocument))
      rb_raise(rb_eArgError, "argument must be a Nokogiri::XML::Document");

    /* handle hashes as arguments. */
    if(T_HASH == TYPE(paramobj)) {
      paramobj = rb_funcall(paramobj, rb_intern("to_a"), 0);
      paramobj = rb_funcall(paramobj, rb_intern("flatten"), 0);
    }

    Check_Type(paramobj, T_ARRAY);

    Data_Get_Struct(xmldoc, xmlDoc, xml);
    Data_Get_Struct(self, xsltStylesheet, ss);

    param_len = RARRAY_LEN(paramobj);
    params = calloc((size_t)param_len+1, sizeof(char*));
    for (j = 0 ; j < param_len ; j++) {
      VALUE entry = rb_ary_entry(paramobj, j);
      const char * ptr = StringValuePtr(entry);
      params[j] = ptr;
    }
    params[param_len] = 0 ;

    result = xsltApplyStylesheet(ss, xml, params);
    free(params);

    if (!result) rb_raise(rb_eRuntimeError, "could not perform xslt transform on document");

    return Nokogiri_wrap_xml_document((VALUE)0, result) ;
}

static void method_caller(xmlXPathParserContextPtr ctxt, int nargs)
{
    const xmlChar * function;
    const xmlChar * functionURI;
    size_t i, count;

    xsltTransformContextPtr transform;
    xmlXPathObjectPtr xpath;
    VALUE obj;
    VALUE *args;
    VALUE result;

    transform = xsltXPathGetTransformContext(ctxt);

    function = ctxt->context->function;
    functionURI = ctxt->context->functionURI;
    obj = (VALUE)xsltGetExtData(transform, functionURI);

    count = (size_t)ctxt->valueNr;
    args = calloc(count, sizeof(VALUE *));

    for(i = 0; i < count; i++) {
	VALUE thing;

	xpath = valuePop(ctxt);
	switch(xpath->type) {
	    case XPATH_STRING:
		thing = NOKOGIRI_STR_NEW2(xpath->stringval);
		break;
	    case XPATH_NODESET:
		if(NULL == xpath->nodesetval) {
		    thing = Nokogiri_wrap_xml_node_set(
			    xmlXPathNodeSetCreate(NULL),
			    DOC_RUBY_OBJECT(ctxt->context->doc));
		} else {
		    thing = Nokogiri_wrap_xml_node_set(xpath->nodesetval,
			    DOC_RUBY_OBJECT(ctxt->context->doc));
		}
		break;
	    default:
		rb_raise(rb_eRuntimeError, "do not handle type: %d", xpath->type);
	}
	args[i] = thing;
    }
    result = rb_funcall3(obj, rb_intern((const char *)function), (int)count, args);
    switch(TYPE(result)) {
	case T_FLOAT:
	case T_BIGNUM:
	case T_FIXNUM:
	    xmlXPathReturnNumber(ctxt, NUM2DBL(result));
	    break;
	case T_STRING:
	    xmlXPathReturnString(
		    ctxt,
		    xmlStrdup((xmlChar *)StringValuePtr(result))
		    );
	    break;
	case T_TRUE:
	    xmlXPathReturnTrue(ctxt);
	    break;
	case T_FALSE:
	    xmlXPathReturnFalse(ctxt);
	    break;
	case T_NIL:
	    break;
	default:
	    rb_raise(rb_eRuntimeError, "Invalid return type");
    }
}

static void * initFunc(xsltTransformContextPtr ctxt, const xmlChar *uri)
{
    VALUE modules = rb_iv_get(xslt, "@modules");
    VALUE obj = rb_hash_aref(modules, rb_str_new2((const char *)uri));
    VALUE args = { Qfalse };
    VALUE methods = rb_funcall(obj, rb_intern("instance_methods"), 1, args);
    int i;

    for(i = 0; i < RARRAY_LEN(methods); i++) {
	VALUE method_name = rb_obj_as_string(RARRAY_PTR(methods)[i]);
	xsltRegisterExtFunction(ctxt,
          (unsigned char *)StringValuePtr(method_name), uri, method_caller);
    }

    return (void *)rb_class_new_instance(0, NULL, obj);
}

static void shutdownFunc(xsltTransformContextPtr ctxt,
	const xmlChar *uri, void *data)
{
}

/*
 *  call-seq:
 *    register(uri, custom_handler_class)
 *
 *  Register a class that implements custom XLST transformation functions.
 */
static VALUE registr(VALUE self, VALUE uri, VALUE obj)
{
    VALUE modules = rb_iv_get(self, "@modules");
    if(NIL_P(modules)) rb_raise(rb_eRuntimeError, "wtf! @modules isn't set");

    rb_hash_aset(modules, uri, obj);
    xsltRegisterExtModule((unsigned char *)StringValuePtr(uri), initFunc, shutdownFunc);
    return self;
}

VALUE cNokogiriXsltStylesheet ;
void init_xslt_stylesheet()
{
  VALUE nokogiri;
  VALUE klass;

  nokogiri = rb_define_module("Nokogiri");
  xslt = rb_define_module_under(nokogiri, "XSLT");
  klass = rb_define_class_under(xslt, "Stylesheet", rb_cObject);

  rb_iv_set(xslt, "@modules", rb_hash_new());

  cNokogiriXsltStylesheet = klass;

  rb_define_singleton_method(klass, "parse_stylesheet_doc", parse_stylesheet_doc, 1);
  rb_define_singleton_method(xslt, "register", registr, 2);
  rb_define_method(klass, "serialize", serialize, 1);
  rb_define_method(klass, "transform", transform, -1);
}
