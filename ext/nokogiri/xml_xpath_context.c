#include <nokogiri.h>

VALUE cNokogiriXmlXpathContext;

/*
 * these constants have matching declarations in
 * ext/java/nokogiri/internals/NokogiriNamespaceContext.java
 */
static const xmlChar *NOKOGIRI_PREFIX = (const xmlChar *)"nokogiri";
static const xmlChar *NOKOGIRI_URI = (const xmlChar *)"http://www.nokogiri.org/default_ns/ruby/extensions_functions";
static const xmlChar *NOKOGIRI_BUILTIN_PREFIX = (const xmlChar *)"nokogiri-builtin";
static const xmlChar *NOKOGIRI_BUILTIN_URI = (const xmlChar *)"https://www.nokogiri.org/default_ns/ruby/builtins";

static void
xml_xpath_context_deallocate(xmlXPathContextPtr ctx)
{
  xmlXPathFreeContext(ctx);
}

/* find a CSS class in an HTML element's `class` attribute */
static const xmlChar *
builtin_css_class(const xmlChar *str, const xmlChar *val)
{
  int val_len;

  if (str == NULL) { return (NULL); }
  if (val == NULL) { return (NULL); }

  val_len = xmlStrlen(val);
  if (val_len == 0) { return (str); }

  while (*str != 0) {
    if ((*str == *val) && !xmlStrncmp(str, val, val_len)) {
      const xmlChar *next_byte = str + val_len;

      /* only match if the next byte is whitespace or end of string */
      if ((*next_byte == 0) || (IS_BLANK_CH(*next_byte))) {
        return ((const xmlChar *)str);
      }
    }

    /* advance str to whitespace */
    while ((*str != 0) && !IS_BLANK_CH(*str)) {
      str++;
    }

    /* advance str to start of next word or end of string */
    while ((*str != 0) && IS_BLANK_CH(*str)) {
      str++;
    }
  }

  return (NULL);
}

/* xmlXPathFunction to wrap builtin_css_class() */
static void
xpath_builtin_css_class(xmlXPathParserContextPtr ctxt, int nargs)
{
  xmlXPathObjectPtr hay, needle;

  CHECK_ARITY(2);

  CAST_TO_STRING;
  needle = valuePop(ctxt);
  if ((needle == NULL) || (needle->type != XPATH_STRING)) {
    xmlXPathFreeObject(needle);
    XP_ERROR(XPATH_INVALID_TYPE);
  }

  CAST_TO_STRING;
  hay = valuePop(ctxt);
  if ((hay == NULL) || (hay->type != XPATH_STRING)) {
    xmlXPathFreeObject(hay);
    xmlXPathFreeObject(needle);
    XP_ERROR(XPATH_INVALID_TYPE);
  }

  if (builtin_css_class(hay->stringval, needle->stringval)) {
    valuePush(ctxt, xmlXPathNewBoolean(1));
  } else {
    valuePush(ctxt, xmlXPathNewBoolean(0));
  }

  xmlXPathFreeObject(hay);
  xmlXPathFreeObject(needle);
}


/* xmlXPathFunction to select nodes whose local name matches, for HTML5 CSS queries that should ignore namespaces */
static void
xpath_builtin_local_name_is(xmlXPathParserContextPtr ctxt, int nargs)
{
  xmlXPathObjectPtr element_name;

  assert(ctxt->context->node);

  CHECK_ARITY(1);
  CAST_TO_STRING;
  CHECK_TYPE(XPATH_STRING);
  element_name = valuePop(ctxt);

  valuePush(ctxt, xmlXPathNewBoolean(xmlStrEqual(ctxt->context->node->name, element_name->stringval)));

  xmlXPathFreeObject(element_name);
}


/*
 * call-seq:
 *  register_ns(prefix, uri)
 *
 * Register the namespace with +prefix+ and +uri+.
 */
static VALUE
rb_xml_xpath_context_register_ns(VALUE self, VALUE prefix, VALUE uri)
{
  xmlXPathContextPtr ctx;
  Data_Get_Struct(self, xmlXPathContext, ctx);

  xmlXPathRegisterNs(ctx,
                     (const xmlChar *)StringValueCStr(prefix),
                     (const xmlChar *)StringValueCStr(uri)
                    );
  return self;
}

/*
 * call-seq:
 *  register_variable(name, value)
 *
 * Register the variable +name+ with +value+.
 */
static VALUE
rb_xml_xpath_context_register_variable(VALUE self, VALUE name, VALUE value)
{
  xmlXPathContextPtr ctx;
  xmlXPathObjectPtr xmlValue;
  Data_Get_Struct(self, xmlXPathContext, ctx);

  xmlValue = xmlXPathNewCString(StringValueCStr(value));

  xmlXPathRegisterVariable(ctx,
                           (const xmlChar *)StringValueCStr(name),
                           xmlValue
                          );

  return self;
}


/*
 *  convert an XPath object into a Ruby object of the appropriate type.
 *  returns Qundef if no conversion was possible.
 */
static VALUE
xpath2ruby(xmlXPathObjectPtr c_xpath_object, xmlXPathContextPtr ctx)
{
  VALUE rb_retval;

  assert(ctx->doc);
  assert(DOC_RUBY_OBJECT_TEST(ctx->doc));

  switch (c_xpath_object->type) {
    case XPATH_STRING:
      rb_retval = NOKOGIRI_STR_NEW2(c_xpath_object->stringval);
      xmlFree(c_xpath_object->stringval);
      return rb_retval;

    case XPATH_NODESET:
      return noko_xml_node_set_wrap(c_xpath_object->nodesetval,
                                    DOC_RUBY_OBJECT(ctx->doc));

    case XPATH_NUMBER:
      return rb_float_new(c_xpath_object->floatval);

    case XPATH_BOOLEAN:
      return (c_xpath_object->boolval == 1) ? Qtrue : Qfalse;

    default:
      return Qundef;
  }
}

void
Nokogiri_marshal_xpath_funcall_and_return_values(
  xmlXPathParserContextPtr ctx,
  int argc,
  VALUE rb_xpath_handler,
  const char *method_name
)
{
  VALUE rb_retval;
  VALUE *argv;
  VALUE rb_node_set = Qnil;
  xmlNodeSetPtr c_node_set = NULL;
  xmlXPathObjectPtr c_xpath_object;

  assert(ctx->context->doc);
  assert(DOC_RUBY_OBJECT_TEST(ctx->context->doc));

  argv = (VALUE *)ruby_xcalloc((size_t)argc, sizeof(VALUE));
  for (int j = 0 ; j < argc ; ++j) {
    rb_gc_register_address(&argv[j]);
  }

  for (int j = argc - 1 ; j >= 0 ; --j) {
    c_xpath_object = valuePop(ctx);
    argv[j] = xpath2ruby(c_xpath_object, ctx->context);
    if (argv[j] == Qundef) {
      argv[j] = NOKOGIRI_STR_NEW2(xmlXPathCastToString(c_xpath_object));
    }
    xmlXPathFreeNodeSetList(c_xpath_object);
  }

  rb_retval = rb_funcall2(rb_xpath_handler, rb_intern((const char *)method_name), argc, argv);

  for (int j = 0 ; j < argc ; ++j) {
    rb_gc_unregister_address(&argv[j]);
  }
  ruby_xfree(argv);

  switch (TYPE(rb_retval)) {
    case T_FLOAT:
    case T_BIGNUM:
    case T_FIXNUM:
      xmlXPathReturnNumber(ctx, NUM2DBL(rb_retval));
      break;
    case T_STRING:
      xmlXPathReturnString(ctx, xmlCharStrdup(StringValueCStr(rb_retval)));
      break;
    case T_TRUE:
      xmlXPathReturnTrue(ctx);
      break;
    case T_FALSE:
      xmlXPathReturnFalse(ctx);
      break;
    case T_NIL:
      break;
    case T_ARRAY: {
      VALUE construct_args[2] = { DOC_RUBY_OBJECT(ctx->context->doc), rb_retval };
      rb_node_set = rb_class_new_instance(2, construct_args, cNokogiriXmlNodeSet);
      Data_Get_Struct(rb_node_set, xmlNodeSet, c_node_set);
      xmlXPathReturnNodeSet(ctx, xmlXPathNodeSetMerge(NULL, c_node_set));
    }
    break;
    case T_DATA:
      if (rb_obj_is_kind_of(rb_retval, cNokogiriXmlNodeSet)) {
        Data_Get_Struct(rb_retval, xmlNodeSet, c_node_set);
        /* Copy the node set, otherwise it will get GC'd. */
        xmlXPathReturnNodeSet(ctx, xmlXPathNodeSetMerge(NULL, c_node_set));
        break;
      }
    default:
      rb_raise(rb_eRuntimeError, "Invalid return type");
  }
}

static void
method_caller(xmlXPathParserContextPtr ctx, int argc)
{
  VALUE rb_xpath_handler = Qnil;
  const char *method_name = NULL ;

  assert(ctx);
  assert(ctx->context);
  assert(ctx->context->userData);
  assert(ctx->context->function);

  rb_xpath_handler = (VALUE)(ctx->context->userData);
  method_name = (const char *)(ctx->context->function);

  Nokogiri_marshal_xpath_funcall_and_return_values(ctx, argc, rb_xpath_handler, method_name);
}

static xmlXPathFunction
handler_lookup(void *ctx, const xmlChar *c_name, const xmlChar *c_ns_uri)
{
  VALUE rb_xpath_handler = (VALUE)ctx;
  if (rb_respond_to(rb_xpath_handler, rb_intern((const char *)c_name))) {
    return method_caller;
  }

  return NULL;
}

PRINTFLIKE_DECL(2, 3)
static void
generic_exception_pusher(void *ctx, const char *msg, ...)
{
  VALUE rb_errors = (VALUE)ctx;
  VALUE rb_message;
  VALUE rb_exception;

  Check_Type(rb_errors, T_ARRAY);

#ifdef TRUFFLERUBY_NOKOGIRI_SYSTEM_LIBRARIES
  /* It is not currently possible to pass var args from native
     functions to sulong, so we work around the issue here. */
  rb_message = rb_sprintf("generic_exception_pusher: %s", msg);
#else
  va_list args;
  va_start(args, msg);
  rb_message = rb_vsprintf(msg, args);
  va_end(args);
#endif

  rb_exception = rb_exc_new_str(cNokogiriXmlXpathSyntaxError, rb_message);
  rb_ary_push(rb_errors, rb_exception);
}

/*
 * call-seq:
 *  evaluate(search_path, handler = nil)
 *
 * Evaluate the +search_path+ returning an XML::XPath object.
 */
static VALUE
rb_xml_xpath_context_evaluate(int argc, VALUE *argv, VALUE self)
{
  VALUE search_path, xpath_handler;
  VALUE retval = Qnil;
  xmlXPathContextPtr ctx;
  xmlXPathObjectPtr xpath;
  xmlChar *query;
  VALUE errors = rb_ary_new();

  Data_Get_Struct(self, xmlXPathContext, ctx);

  if (rb_scan_args(argc, argv, "11", &search_path, &xpath_handler) == 1) {
    xpath_handler = Qnil;
  }

  query = (xmlChar *)StringValueCStr(search_path);

  if (Qnil != xpath_handler) {
    /* FIXME: not sure if this is the correct place to shove private data. */
    ctx->userData = (void *)xpath_handler;
    xmlXPathRegisterFuncLookup(ctx, handler_lookup, (void *)xpath_handler);
  }

  xmlSetStructuredErrorFunc((void *)errors, Nokogiri_error_array_pusher);
  xmlSetGenericErrorFunc((void *)errors, generic_exception_pusher);

  xpath = xmlXPathEvalExpression(query, ctx);

  xmlSetStructuredErrorFunc(NULL, NULL);
  xmlSetGenericErrorFunc(NULL, NULL);

  if (xpath == NULL) {
    rb_exc_raise(rb_ary_entry(errors, 0));
  }

  retval = xpath2ruby(xpath, ctx);
  if (retval == Qundef) {
    retval = noko_xml_node_set_wrap(NULL, DOC_RUBY_OBJECT(ctx->doc));
  }

  xmlXPathFreeNodeSetList(xpath);

  return retval;
}

/*
 * call-seq:
 *  new(node)
 *
 * Create a new XPathContext with +node+ as the reference point.
 */
static VALUE
rb_xml_xpath_context_new(VALUE klass, VALUE nodeobj)
{
  xmlNodePtr node;
  xmlXPathContextPtr ctx;
  VALUE self;

  Noko_Node_Get_Struct(nodeobj, xmlNode, node);

#if LIBXML_VERSION < 21000
  /* deprecated in 40483d0 */
  xmlXPathInit();
#endif

  ctx = xmlXPathNewContext(node->doc);
  ctx->node = node;

  xmlXPathRegisterNs(ctx, NOKOGIRI_PREFIX, NOKOGIRI_URI);
  xmlXPathRegisterNs(ctx, NOKOGIRI_BUILTIN_PREFIX, NOKOGIRI_BUILTIN_URI);
  xmlXPathRegisterFuncNS(ctx, (const xmlChar *)"css-class", NOKOGIRI_BUILTIN_URI,
                         xpath_builtin_css_class);
  xmlXPathRegisterFuncNS(ctx, (const xmlChar *)"local-name-is", NOKOGIRI_BUILTIN_URI,
                         xpath_builtin_local_name_is);

  self = Data_Wrap_Struct(klass, 0, xml_xpath_context_deallocate, ctx);
  return self;
}

void
noko_init_xml_xpath_context(void)
{
  /*
   * XPathContext is the entry point for searching a Document by using XPath.
   */
  cNokogiriXmlXpathContext = rb_define_class_under(mNokogiriXml, "XPathContext", rb_cObject);

  rb_undef_alloc_func(cNokogiriXmlXpathContext);

  rb_define_singleton_method(cNokogiriXmlXpathContext, "new", rb_xml_xpath_context_new, 1);

  rb_define_method(cNokogiriXmlXpathContext, "evaluate", rb_xml_xpath_context_evaluate, -1);
  rb_define_method(cNokogiriXmlXpathContext, "register_variable", rb_xml_xpath_context_register_variable, 2);
  rb_define_method(cNokogiriXmlXpathContext, "register_ns", rb_xml_xpath_context_register_ns, 2);
}
