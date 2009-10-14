#include <xml_syntax_error.h>

static void dealloc(xmlErrorPtr ptr)
{
  NOKOGIRI_DEBUG_START(ptr);
  xmlResetError(ptr);
  xmlFree(ptr);
  NOKOGIRI_DEBUG_END(ptr);
}

static VALUE allocate(VALUE klass)
{
  xmlErrorPtr error = xmlMalloc(sizeof(xmlError));
  memset(error, 0, sizeof(xmlError));
  return Data_Wrap_Struct(klass, NULL, dealloc, error);
}

/*
 * call-seq:
 *  column
 *
 * Column number or 0 if not available
 */
static VALUE column(VALUE self)
{
  xmlErrorPtr error;
  Data_Get_Struct(self, xmlError, error);
  return INT2NUM(error->int2);
}

/*
 * call-seq:
 *  int1
 *
 * Extra number information
 */
static VALUE int1(VALUE self)
{
  xmlErrorPtr error;
  Data_Get_Struct(self, xmlError, error);
  return INT2NUM(error->int1);
}

/*
 * call-seq:
 *  str3
 *
 * Extra string information
 */
static VALUE str3(VALUE self)
{
  xmlErrorPtr error;
  Data_Get_Struct(self, xmlError, error);
  if(error->str3) return NOKOGIRI_STR_NEW2(error->str3);
  return Qnil;
}

/*
 * call-seq:
 *  str2
 *
 * Extra string information
 */
static VALUE str2(VALUE self)
{
  xmlErrorPtr error;
  Data_Get_Struct(self, xmlError, error);
  if(error->str2) return NOKOGIRI_STR_NEW2(error->str2);
  return Qnil;
}

/*
 * call-seq:
 *  str1
 *
 * Extra string information
 */
static VALUE str1(VALUE self)
{
  xmlErrorPtr error;
  Data_Get_Struct(self, xmlError, error);
  if(error->str1) return NOKOGIRI_STR_NEW2(error->str1);
  return Qnil;
}

/*
 * call-seq:
 *  line
 *
 * Get the line number of the error
 */
static VALUE line(VALUE self)
{
  xmlErrorPtr error;
  Data_Get_Struct(self, xmlError, error);
  return INT2NUM(error->line);
}

/*
 * call-seq:
 *  file
 *
 * Get the filename for the error
 */
static VALUE file(VALUE self)
{
  xmlErrorPtr error;
  Data_Get_Struct(self, xmlError, error);
  if(error->file) return NOKOGIRI_STR_NEW2(error->file);

  return Qnil;
}

/*
 * call-seq:
 *  level
 *
 * Get the error level
 */
static VALUE level(VALUE self)
{
  xmlErrorPtr error;
  Data_Get_Struct(self, xmlError, error);
  return INT2NUM((short)error->level);
}

/*
 * call-seq:
 *  code
 *
 * Get the error code
 */
static VALUE code(VALUE self)
{
  xmlErrorPtr error;
  Data_Get_Struct(self, xmlError, error);
  return INT2NUM(error->code);
}

/*
 * call-seq:
 *  domain
 *
 * Get the part of the library that raised this exception
 */
static VALUE domain(VALUE self)
{
  xmlErrorPtr error;
  Data_Get_Struct(self, xmlError, error);
  return INT2NUM(error->domain);
}

/*
 * call-seq:
 *  message
 *
 * Get the human readable message.
 */
static VALUE message(VALUE self)
{
  xmlErrorPtr error;
  Data_Get_Struct(self, xmlError, error);
  if(error->message) return NOKOGIRI_STR_NEW2(error->message);
  return Qnil;
}

/*
 * call-seq:
 *  message=
 *
 * Set the human readable message.
 */
static VALUE set_message(VALUE self, VALUE _message)
{
  xmlErrorPtr error;
  Data_Get_Struct(self, xmlError, error);

  if(error->message) {
    xmlFree(error->message);
    error->message = 0;
  }

  if(RTEST(_message)) {
    error->message = xmlMalloc(RSTRING_LEN(_message) + 1);
    memset(error->message, 0, RSTRING_LEN(_message) + 1);
    memcpy(error->message, StringValuePtr(_message), RSTRING_LEN(_message));
  }

  return message;
}

/*
 * call-seq:
 *  initialize_copy(old_copy)
 *
 * Initialize a copy of the +old_copy+
 */
static VALUE initialize_copy(VALUE self, VALUE _old_copy)
{
  if(!rb_obj_is_kind_of(_old_copy, cNokogiriXmlSyntaxError))
    rb_raise(rb_eArgError, "node must be a Nokogiri::XML::SyntaxError");

  xmlErrorPtr error, old_error;
  Data_Get_Struct(self, xmlError, error);
  Data_Get_Struct(_old_copy, xmlError, old_error);

  xmlCopyError(old_error, error);

  return message;
}

void Nokogiri_error_array_pusher(void * ctx, xmlErrorPtr error)
{
  VALUE list = (VALUE)ctx;
  rb_ary_push(list,  Nokogiri_wrap_xml_syntax_error((VALUE)NULL, error));
}

void Nokogiri_error_raise(void * ctx, xmlErrorPtr error)
{
  rb_exc_raise(Nokogiri_wrap_xml_syntax_error((VALUE)NULL, error));
}

VALUE Nokogiri_wrap_xml_syntax_error(VALUE klass, xmlErrorPtr error)
{
  if(!klass) klass = cNokogiriXmlSyntaxError;

  xmlErrorPtr ptr = calloc(1, sizeof(xmlError));
  xmlCopyError(error, ptr);

  return Data_Wrap_Struct(klass, NULL, dealloc, ptr);
}

VALUE cNokogiriXmlSyntaxError;
void init_xml_syntax_error()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");

  /*
   * The XML::SyntaxError is raised on parse errors
   */
  VALUE syntax_error_mommy = rb_define_class_under(nokogiri, "SyntaxError", rb_eStandardError);
  VALUE klass = rb_define_class_under(xml, "SyntaxError", syntax_error_mommy);
  cNokogiriXmlSyntaxError = klass;

  rb_define_alloc_func(klass, allocate);

  rb_define_method(klass, "message", message, 0);
  rb_define_method(klass, "message=", set_message, 1);
  rb_define_method(klass, "initialize_copy", initialize_copy, 1);
  rb_define_method(klass, "domain", domain, 0);
  rb_define_method(klass, "code", code, 0);
  rb_define_method(klass, "level", level, 0);
  rb_define_method(klass, "file", file, 0);
  rb_define_method(klass, "line", line, 0);
  rb_define_method(klass, "str1", str1, 0);
  rb_define_method(klass, "str2", str2, 0);
  rb_define_method(klass, "str3", str3, 0);
  rb_define_method(klass, "int1", int1, 0);
  rb_define_method(klass, "column", column, 0);
}
