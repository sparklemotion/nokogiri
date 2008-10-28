#include <xml_dtd.h>

static void notation_copier(void *payload, void *data, xmlChar *name)
{
  VALUE hash = (VALUE)data;
  VALUE klass = rb_const_get(mNokogiriXml, rb_intern("Notation"));

  xmlNotationPtr c_notation = (xmlNotationPtr)payload;

  VALUE notation = rb_funcall(klass, rb_intern("new"), 3,
      c_notation->name ? rb_str_new2((const char *)c_notation->name) : Qnil,
      c_notation->PublicID ? rb_str_new2((const char *)c_notation->PublicID) : Qnil,
      c_notation->SystemID ? rb_str_new2((const char *)c_notation->SystemID) : Qnil);

  rb_hash_aset(hash, rb_str_new2(name), notation);
}

/*
 * call-seq:
 *   notations
 *
 * Get a hash of the notations for this DTD.
 */
static VALUE notations(VALUE self)
{
  xmlDtdPtr dtd;
  Data_Get_Struct(self, xmlDtd, dtd);

  if(!dtd->notations) return Qnil;

  VALUE hash = rb_hash_new();

  xmlHashScan((xmlHashTablePtr)dtd->notations, notation_copier, (void *)hash);

  return hash;
}

void init_xml_dtd()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE klass = rb_define_class_under(xml, "DTD", cNokogiriXmlNode);

  rb_define_method(klass, "notations", notations, 0);
}
