#include <nokogiri.h>

VALUE cNokogiriXsltStylesheet;

static void
mark(void *data)
{
  nokogiriXsltStylesheetTuple *wrapper = (nokogiriXsltStylesheetTuple *)data;
  rb_gc_mark(wrapper->func_instances);
}

static void
dealloc(void *data)
{
  nokogiriXsltStylesheetTuple *wrapper = (nokogiriXsltStylesheetTuple *)data;
  xsltStylesheetPtr doc = wrapper->ss;
  xsltFreeStylesheet(doc);
  ruby_xfree(wrapper);
}

static const rb_data_type_t nokogiri_xslt_stylesheet_tuple_type = {
  .wrap_struct_name = "nokogiriXsltStylesheetTuple",
  .function = {
    .dmark = mark,
    .dfree = dealloc,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

PRINTFLIKE_DECL(2, 3)
static void
xslt_generic_error_handler(void *ctx, const char *msg, ...)
{
  VALUE message;

#ifdef TRUFFLERUBY_NOKOGIRI_SYSTEM_LIBRARIES
  /* It is not currently possible to pass var args from native
     functions to sulong, so we work around the issue here. */
  message = rb_sprintf("xslt_generic_error_handler: %s", msg);
#else
  va_list args;
  va_start(args, msg);
  message = rb_vsprintf(msg, args);
  va_end(args);
#endif

  rb_str_concat((VALUE)ctx, message);
}

PRINTFLIKE_DECL(2, 3)
static void
ignore_error(void *ctx, const char *msg, ...)
{
}

/*
 * A Ruby exception must not unwind through libxslt's stack frames, because that skips libxslt's
 * cleanup and leaks memory, and skips the reset of the error handlers. So an extension function is
 * called under rb_protect, and the exception is re-raised after the transform returns.
 *
 * Until then, no Ruby code may run: the pending exception lives only in the thread's errinfo,
 * which a rescue elsewhere would overwrite.
 */
typedef struct {
  int exception_state;
} _noko_xslt_stylesheet__function_call_t;

typedef struct {
  xmlXPathParserContextPtr ctxt;
  int nargs;
} _noko_xslt_stylesheet__invoke_args_t;

VALUE
Nokogiri_wrap_xslt_stylesheet(xsltStylesheetPtr ss)
{
  VALUE self;
  nokogiriXsltStylesheetTuple *wrapper;

  self = TypedData_Make_Struct(
           cNokogiriXsltStylesheet,
           nokogiriXsltStylesheetTuple,
           &nokogiri_xslt_stylesheet_tuple_type,
           wrapper
         );

  ss->_private = (void *)self;
  wrapper->ss = ss;
  wrapper->func_instances = rb_ary_new();

  return self;
}

/*
 * call-seq:
 *   parse_stylesheet_doc(document)
 *
 * Parse an XSLT::Stylesheet from +document+.
 *
 * [Parameters]
 * - +document+ (Nokogiri::XML::Document) the document to be parsed.
 *
 * [Returns] Nokogiri::XSLT::Stylesheet
 */
static VALUE
parse_stylesheet_doc(VALUE klass, VALUE xmldocobj)
{
  xmlDocPtr xml, xml_cpy;
  VALUE errstr, exception;
  xsltStylesheetPtr ss ;

  xml = noko_xml_document_unwrap(xmldocobj);

  errstr = rb_str_new(0, 0);
  xsltSetGenericErrorFunc((void *)errstr, xslt_generic_error_handler);

  xml_cpy = xmlCopyDoc(xml, 1); /* 1 => recursive */
  ss = xsltParseStylesheetDoc(xml_cpy);

  xsltSetGenericErrorFunc(NULL, NULL);

  if (!ss) {
    xmlFreeDoc(xml_cpy);
    exception = rb_exc_new3(rb_eRuntimeError, errstr);
    rb_exc_raise(exception);
  }

  return Nokogiri_wrap_xslt_stylesheet(ss);
}


/*
 * call-seq:
 *   serialize(document)
 *
 * Serialize +document+ to an xml string, as specified by the +method+ parameter in the Stylesheet.
 */
static VALUE
rb_xslt_stylesheet_serialize(VALUE self, VALUE xmlobj)
{
  xmlDocPtr xml ;
  nokogiriXsltStylesheetTuple *wrapper;
  xmlChar *doc_ptr ;
  int doc_len ;
  VALUE rval ;

  xml = noko_xml_document_unwrap(xmlobj);
  TypedData_Get_Struct(
    self,
    nokogiriXsltStylesheetTuple,
    &nokogiri_xslt_stylesheet_tuple_type,
    wrapper
  );
  xsltSaveResultToString(&doc_ptr, &doc_len, xml, wrapper->ss);
  rval = NOKOGIRI_STR_NEW(doc_ptr, doc_len);
  xmlFree(doc_ptr);
  return rval ;
}


/*
 * Build the C-string params array passed to xsltApplyStylesheet.
 *
 * Note: params[j] is a raw pointer into a Ruby string's buffer, and we do not pin the underlying
 * VALUEs against GC compaction. This is safe (despite not pinning the VALUEs) because libxslt fully
 * processes params (interning names, evaluating values) before template execution begins, and Ruby
 * callbacks can only run during template execution. By the time GC compaction is reachable, libxslt
 * no longer reads params[].
 */
typedef struct {
  VALUE rb_param;
  long param_len;
  const char **params;
} build_xslt_params_args_t;

static VALUE
build_xslt_params(VALUE args_ptr)
{
  build_xslt_params_args_t *args = (build_xslt_params_args_t *)args_ptr;

  for (long j = 0; j < args->param_len; j++) {
    VALUE entry = rb_ary_entry(args->rb_param, j);
    args->params[j] = StringValueCStr(entry);
  }

  return Qnil;
}

/*
 * call-seq:
 *   transform(document)
 *   transform(document, params = {})
 *
 * Transform an XML::Document as defined by an XSLT::Stylesheet.
 *
 * [Parameters]
 * - +document+ (Nokogiri::XML::Document) the document to be transformed.
 * - +params+ (Hash, Array) strings used as XSLT parameters.
 *
 * [Returns] Nokogiri::XML::Document
 *
 * *Example* of basic transformation:
 *
 *   xslt = <<~XSLT
 *     <xsl:stylesheet version="1.0"
 *     xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 *
 *     <xsl:param name="title"/>
 *
 *     <xsl:template match="/">
 *       <html>
 *         <body>
 *           <h1><xsl:value-of select="$title"/></h1>
 *           <ol>
 *             <xsl:for-each select="staff/employee">
 *               <li><xsl:value-of select="employeeId"></li>
 *             </xsl:for-each>
 *           </ol>
 *         </body>
 *       </html>
 *     </xsl:stylesheet>
 *   XSLT
 *
 *   xml = <<~XML
 *     <?xml version="1.0"?>
 *     <staff>
 *       <employee>
 *         <employeeId>EMP0001</employeeId>
 *         <position>Accountant</position>
 *       </employee>
 *       <employee>
 *         <employeeId>EMP0002</employeeId>
 *         <position>Developer</position>
 *       </employee>
 *     </staff>
 *   XML
 *
 *   doc = Nokogiri::XML::Document.parse(xml)
 *   stylesheet = Nokogiri::XSLT.parse(xslt)
 *
 * ⚠️️ Note that the +h1+ element is empty because no param has been provided!
 *
 *   stylesheet.transform(doc).to_xml
 *   # => "<html><body>\n" +
 *   #    "<h1></h1>\n" +
 *   #    "<ol>\n" +
 *   #    "<li>EMP0001</li>\n" +
 *   #    "<li>EMP0002</li>\n" +
 *   #    "</ol>\n" +
 *   #    "</body></html>\n"
 *
 * *Example* of using an input parameter hash:
 *
 * ⚠️️ The title is populated, but note how we need to quote-escape the value.
 *
 *   stylesheet.transform(doc, { "title" => "'Employee List'" }).to_xml
 *   # => "<html><body>\n" +
 *   #    "<h1>Employee List</h1>\n" +
 *   #    "<ol>\n" +
 *   #    "<li>EMP0001</li>\n" +
 *   #    "<li>EMP0002</li>\n" +
 *   #    "</ol>\n" +
 *   #    "</body></html>\n"
 *
 * *Example* using the XSLT.quote_params helper method to safely quote-escape strings:
 *
 *   stylesheet.transform(doc, Nokogiri::XSLT.quote_params({ "title" => "Aaron's List" })).to_xml
 *   # => "<html><body>\n" +
 *   #    "<h1>Aaron's List</h1>\n" +
 *   #    "<ol>\n" +
 *   #    "<li>EMP0001</li>\n" +
 *   #    "<li>EMP0002</li>\n" +
 *   #    "</ol>\n" +
 *   #    "</body></html>\n"
 *
 * *Example* using an array of XSLT parameters
 *
 * You can also use an array if you want to.
 *
 *   stylesheet.transform(doc, ["title", "'Employee List'"]).to_xml
 *   # => "<html><body>\n" +
 *   #    "<h1>Employee List</h1>\n" +
 *   #    "<ol>\n" +
 *   #    "<li>EMP0001</li>\n" +
 *   #    "<li>EMP0002</li>\n" +
 *   #    "</ol>\n" +
 *   #    "</body></html>\n"
 *
 * Or pass an array to XSLT.quote_params:
 *
 *   stylesheet.transform(doc, Nokogiri::XSLT.quote_params(["title", "Aaron's List"])).to_xml
 *   # => "<html><body>\n" +
 *   #    "<h1>Aaron's List</h1>\n" +
 *   #    "<ol>\n" +
 *   #    "<li>EMP0001</li>\n" +
 *   #    "<li>EMP0002</li>\n" +
 *   #    "</ol>\n" +
 *   #    "</body></html>\n"
 *
 * See: Nokogiri::XSLT.quote_params
 */
static VALUE
rb_xslt_stylesheet_transform(int argc, VALUE *argv, VALUE self)
{
  VALUE rb_document, rb_param, rb_error_str;
  xmlDocPtr c_document ;
  xmlDocPtr c_result_document ;
  nokogiriXsltStylesheetTuple *wrapper;
  const char **params ;
  long param_len ;
  int parse_error_occurred ;
  int defensive_copy_p = 0;
  _noko_xslt_stylesheet__function_call_t function_call = { 0 };

  rb_scan_args(argc, argv, "11", &rb_document, &rb_param);
  if (NIL_P(rb_param)) { rb_param = rb_ary_new2(0L) ; }
  if (!rb_obj_is_kind_of(rb_document, cNokogiriXmlDocument)) {
    rb_raise(rb_eArgError, "argument must be a Nokogiri::XML::Document");
  }

  /* handle hashes as arguments. */
  if (T_HASH == TYPE(rb_param)) {
    rb_param = rb_funcall(rb_param, rb_intern("to_a"), 0);
    rb_param = rb_funcall(rb_param, rb_intern("flatten"), 0);
  }

  Check_Type(rb_param, T_ARRAY);

  c_document = noko_xml_document_unwrap(rb_document);
  TypedData_Get_Struct(self, nokogiriXsltStylesheetTuple, &nokogiri_xslt_stylesheet_tuple_type, wrapper);

  param_len = RARRAY_LEN(rb_param);
  params = ruby_xcalloc((size_t)param_len + 1, sizeof(char *));
  {
    // populate params under rb_protect so that a raise from StringValueCStr
    // (e.g. on a null byte) does not leak the params allocation.
    build_xslt_params_args_t args = { rb_param, param_len, params };
    int state = 0;

    rb_protect(build_xslt_params, (VALUE)&args, &state);
    if (state) {
      ruby_xfree(params);
      rb_jump_tag(state);
    }
  }
  params[param_len] = 0 ;

  xsltTransformContextPtr c_transform_context = xsltNewTransformContext(wrapper->ss, c_document);
  if (xsltNeedElemSpaceHandling(c_transform_context) &&
      noko_xml_document_has_wrapped_blank_nodes_p(c_document)) {
    // see https://github.com/sparklemotion/nokogiri/issues/2800
    c_document = xmlCopyDoc(c_document, 1);
    defensive_copy_p = 1;
  }
  xsltFreeTransformContext(c_transform_context);

  c_transform_context = xsltNewTransformContext(wrapper->ss, c_document);
  if (c_transform_context == NULL) {
    ruby_xfree(params);
    if (defensive_copy_p) {
      xmlFreeDoc(c_document);
    }
    rb_raise(rb_eRuntimeError, "could not create an XSLT transform context");
  }
  c_transform_context->_private = &function_call;

  rb_error_str = rb_str_new(0, 0);
  xsltSetGenericErrorFunc((void *)rb_error_str, xslt_generic_error_handler);
  xmlSetGenericErrorFunc((void *)rb_error_str, xslt_generic_error_handler);

  c_result_document = xsltApplyStylesheetUser(wrapper->ss, c_document, params, NULL, NULL, c_transform_context);
  xsltFreeTransformContext(c_transform_context);

  ruby_xfree(params);
  if (defensive_copy_p) {
    xmlFreeDoc(c_document);
    c_document = NULL;
  }

  xsltSetGenericErrorFunc(NULL, NULL);
  xmlSetGenericErrorFunc(NULL, NULL);

  if (function_call.exception_state != 0) {
    xmlFreeDoc(c_result_document);
    rb_jump_tag(function_call.exception_state);
  }

  parse_error_occurred = (Qfalse == rb_funcall(rb_error_str, rb_intern("empty?"), 0));

  if (parse_error_occurred) {
    rb_exc_raise(rb_exc_new3(rb_eRuntimeError, rb_error_str));
  }

  return noko_xml_document_wrap((VALUE)0, c_result_document) ;
}

static VALUE
invoke_function(VALUE data)
{
  _noko_xslt_stylesheet__invoke_args_t *args = (_noko_xslt_stylesheet__invoke_args_t *)data;
  xsltTransformContextPtr transform = xsltXPathGetTransformContext(args->ctxt);
  VALUE handler = (VALUE)xsltGetExtData(transform, args->ctxt->context->functionURI);

  Nokogiri_marshal_xpath_funcall_and_return_values(
    args->ctxt,
    args->nargs,
    handler,
    (const char *)(args->ctxt->context->function)
  );

  return Qnil;
}

static void
method_caller(xmlXPathParserContextPtr ctxt, int nargs)
{
  xsltTransformContextPtr transform = xsltXPathGetTransformContext(ctxt);
  _noko_xslt_stylesheet__function_call_t *function_call = transform->_private;
  _noko_xslt_stylesheet__invoke_args_t args = { ctxt, nargs };

  if (function_call->exception_state == 0) {
    rb_protect(invoke_function, (VALUE)&args, &function_call->exception_state);
  }

  if (function_call->exception_state != 0) {
    /* silence the errors libxslt reports while it stops, which would run Ruby code */
    xsltSetGenericErrorFunc(NULL, ignore_error);
    xmlSetGenericErrorFunc(NULL, ignore_error);

    ctxt->error = XPATH_EXPR_ERROR;
    transform->state = XSLT_STATE_STOPPED;
  }
}

static void *
initFunc(xsltTransformContextPtr ctxt, const xmlChar *uri)
{
  VALUE modules = rb_iv_get(mNokogiriXslt, "@modules");
  VALUE obj = rb_hash_aref(modules, rb_str_new2((const char *)uri));
  VALUE args = { Qfalse };
  VALUE methods = rb_funcall(obj, rb_intern("instance_methods"), 1, args);
  VALUE inst;
  nokogiriXsltStylesheetTuple *wrapper;
  int i;

  for (i = 0; i < RARRAY_LEN(methods); i++) {
    VALUE method_name = rb_obj_as_string(rb_ary_entry(methods, i));
    xsltRegisterExtFunction(
      ctxt,
      (unsigned char *)StringValueCStr(method_name),
      uri,
      method_caller
    );
  }

  TypedData_Get_Struct(
    (VALUE)ctxt->style->_private,
    nokogiriXsltStylesheetTuple,
    &nokogiri_xslt_stylesheet_tuple_type,
    wrapper
  );
  inst = rb_class_new_instance(0, NULL, obj);
  rb_ary_push(wrapper->func_instances, inst);

  return (void *)inst;
}

static void
shutdownFunc(xsltTransformContextPtr ctxt,
             const xmlChar *uri, void *data)
{
  nokogiriXsltStylesheetTuple *wrapper;

  TypedData_Get_Struct(
    (VALUE)ctxt->style->_private,
    nokogiriXsltStylesheetTuple,
    &nokogiri_xslt_stylesheet_tuple_type,
    wrapper
  );

  rb_ary_clear(wrapper->func_instances);
}

/* docstring is in lib/nokogiri/xslt.rb */
static VALUE
rb_xslt_s_register(VALUE self, VALUE uri, VALUE obj)
{
  VALUE modules = rb_iv_get(self, "@modules");
  if (NIL_P(modules)) {
    rb_raise(rb_eRuntimeError, "internal error: @modules not set");
  }

  rb_hash_aset(modules, uri, obj);
  xsltRegisterExtModule(
    (unsigned char *)StringValueCStr(uri),
    initFunc,
    shutdownFunc
  );
  return self;
}

void
noko_init_xslt_stylesheet(void)
{
  rb_define_singleton_method(mNokogiriXslt, "register", rb_xslt_s_register, 2);
  rb_iv_set(mNokogiriXslt, "@modules", rb_hash_new());

  cNokogiriXsltStylesheet = rb_define_class_under(mNokogiriXslt, "Stylesheet", rb_cObject);

  rb_undef_alloc_func(cNokogiriXsltStylesheet);

  rb_define_singleton_method(cNokogiriXsltStylesheet, "parse_stylesheet_doc", parse_stylesheet_doc, 1);
  rb_define_method(cNokogiriXsltStylesheet, "serialize", rb_xslt_stylesheet_serialize, 1);
  rb_define_method(cNokogiriXsltStylesheet, "transform", rb_xslt_stylesheet_transform, -1);
}
