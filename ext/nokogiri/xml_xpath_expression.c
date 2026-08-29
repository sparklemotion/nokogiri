#include <nokogiri.h>

VALUE cNokogiriXmlXpathExpression;

static void
_noko_xml_xpath_expression_dfree(void *data)
{
  xmlXPathCompExprPtr c_expr = (xmlXPathCompExprPtr)data;
  xmlXPathFreeCompExpr(c_expr);
}

static size_t
_noko_xml_xpath_expression_dsize(const void *data)
{
  return 0; // TODO
}

static const rb_data_type_t _noko_xml_xpath_expression_type = {
  .wrap_struct_name = "xmlXPathCompExpr",
  .function = {
    .dfree = _noko_xml_xpath_expression_dfree,
    .dsize = _noko_xml_xpath_expression_dsize,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

static VALUE
noko_xml_xpath_expression_s_new(VALUE klass, VALUE rb_input)
{
  xmlXPathCompExprPtr c_expr = NULL;
  VALUE rb_expr = Qnil;
  VALUE rb_errors = rb_ary_new();

  xmlSetStructuredErrorFunc((void *)rb_errors, noko__error_array_pusher);

  c_expr = xmlXPathCompile((const xmlChar *)StringValueCStr(rb_input));

  xmlSetStructuredErrorFunc(NULL, NULL);

  if (c_expr == NULL) {
    rb_exc_raise(rb_ary_entry(rb_errors, 0));
  }

  rb_expr = TypedData_Wrap_Struct(klass, &_noko_xml_xpath_expression_type, c_expr);
  return rb_expr;
}

xmlXPathCompExprPtr
noko_xml_xpath_expression_unwrap(VALUE rb_expression)
{
  xmlXPathCompExprPtr c_expression;
  TypedData_Get_Struct(rb_expression, xmlXPathCompExpr, &_noko_xml_xpath_expression_type, c_expression);
  return c_expression;
}

void
noko_init_xml_xpath_expression(void)
{
  /*
   *  Nokogiri::XML::XPath::Expression is a compiled XPath expression that can be created to
   *  prepare frequently-used search queries. Preparing them once and re-using them is generally
   *  faster than re-parsing the expression from a string each time it's used.
   */
  cNokogiriXmlXpathExpression = rb_define_class_under(mNokogiriXmlXpath, "Expression", rb_cObject);
  rb_gc_register_mark_object(cNokogiriXmlXpathExpression);

  rb_undef_alloc_func(cNokogiriXmlXpathExpression);

  rb_define_singleton_method(cNokogiriXmlXpathExpression, "new", noko_xml_xpath_expression_s_new, 1);
}
