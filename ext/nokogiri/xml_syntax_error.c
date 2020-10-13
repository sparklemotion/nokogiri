#include <xml_syntax_error.h>

void Nokogiri_error_array_pusher(void * ctx, xmlErrorPtr error)
{
  VALUE list = (VALUE)ctx;
  Check_Type(list, T_ARRAY);
  rb_ary_push(list,  Nokogiri_wrap_xml_syntax_error(error));
}

void Nokogiri_error_raise(void * ctx, xmlErrorPtr error)
{
  rb_exc_raise(Nokogiri_wrap_xml_syntax_error(error));
}

void Nokogiri_generic_error_array_pusher(void * ctx, const char *msg, ...)
{
  va_list args;
  char * message;
  VALUE error_list = (VALUE)ctx;
  VALUE message_rb;

  Check_Type(error_list, T_ARRAY);

  va_start(args, msg);
  vasprintf(&message, msg, args);
  va_end(args);

  message_rb = NOKOGIRI_STR_NEW2(message);
  rb_ary_push(error_list,
              rb_class_new_instance(1, &message_rb, cNokogiriXmlXpathSyntaxError));

  free(message);
}

VALUE Nokogiri_wrap_xml_syntax_error(xmlErrorPtr error)
{
  VALUE msg, e, klass;

  klass = cNokogiriXmlSyntaxError;

  if (error && error->domain == XML_FROM_XPATH) {
    klass = cNokogiriXmlXpathSyntaxError;
  }

  msg = (error && error->message) ? NOKOGIRI_STR_NEW2(error->message) : Qnil;

  e = rb_class_new_instance(
      1,
      &msg,
      klass
  );

  if (error)
  {
    rb_iv_set(e, "@domain", INT2NUM(error->domain));
    rb_iv_set(e, "@code", INT2NUM(error->code));
    rb_iv_set(e, "@level", INT2NUM((short)error->level));
    rb_iv_set(e, "@file", RBSTR_OR_QNIL(error->file));
    rb_iv_set(e, "@line", INT2NUM(error->line));
    rb_iv_set(e, "@str1", RBSTR_OR_QNIL(error->str1));
    rb_iv_set(e, "@str2", RBSTR_OR_QNIL(error->str2));
    rb_iv_set(e, "@str3", RBSTR_OR_QNIL(error->str3));
    rb_iv_set(e, "@int1", INT2NUM(error->int1));
    rb_iv_set(e, "@column", INT2NUM(error->int2));
  }

  return e;
}

VALUE cNokogiriXmlSyntaxError;
VALUE cNokogiriXmlXpathSyntaxError;
void init_xml_syntax_error()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");

  VALUE syntax_error_mommy = rb_define_class_under(nokogiri, "SyntaxError", rb_eStandardError);
  cNokogiriXmlSyntaxError = rb_define_class_under(xml, "SyntaxError", syntax_error_mommy);

  VALUE xml_xpath = rb_define_class_under(mNokogiriXml, "XPath", rb_cObject);
  cNokogiriXmlXpathSyntaxError = rb_define_class_under(xml_xpath, "SyntaxError", cNokogiriXmlSyntaxError);
}
