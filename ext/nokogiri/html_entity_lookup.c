#include <nokogiri.h>

VALUE cNokogiriHtmlEntityDescription;
static VALUE cNokogiriHtmlEntityLookup = 0;

/*
 * call-seq:
 *  get(key)
 *
 * Get the HTML::EntityDescription for +key+
 */
static VALUE
get(VALUE self, VALUE key)
{
  const htmlEntityDesc *desc =
    htmlEntityLookup((const xmlChar *)StringValueCStr(key));
  VALUE args[3];

  if (NULL == desc) { return Qnil; }

  args[0] = INT2NUM((long)desc->value);
  args[1] = NOKOGIRI_STR_NEW2(desc->name);
  args[2] = NOKOGIRI_STR_NEW2(desc->desc);

  if (!cNokogiriHtmlEntityDescription) {
    cNokogiriHtmlEntityDescription = rb_const_get_at(mNokogiriHtml, rb_intern("EntityDescription"));
  }
  return rb_class_new_instance(3, args, cNokogiriHtmlEntityDescription);
}

void
noko_init_html_entity_lookup()
{
  cNokogiriHtmlEntityLookup = rb_define_class_under(mNokogiriHtml, "EntityLookup", rb_cObject);

  rb_define_method(cNokogiriHtmlEntityLookup, "get", get, 1);
}
