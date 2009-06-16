#include <html_entity_lookup.h>

/*
 * call-seq:
 *  get(key)
 *
 * Get the HTML::EntityDescription for +key+
 */
static VALUE get(VALUE self, VALUE key)
{
  const htmlEntityDesc * desc =
    htmlEntityLookup((const xmlChar *)StringValuePtr(key));

  if(NULL == desc) return Qnil;
  VALUE klass = rb_const_get(mNokogiriHtml, rb_intern("EntityDescription"));

  return rb_funcall(klass, rb_intern("new"), 3,
      INT2NUM((int)desc->value),
      NOKOGIRI_STR_NEW2(desc->name, "UTF-8"),
      NOKOGIRI_STR_NEW2(desc->desc, "UTF-8"));
}

void init_html_entity_lookup()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE html = rb_define_module_under(nokogiri, "HTML");
  VALUE klass = rb_define_class_under(html, "EntityLookup", rb_cObject);

  rb_define_method(klass, "get", get, 1);
}
