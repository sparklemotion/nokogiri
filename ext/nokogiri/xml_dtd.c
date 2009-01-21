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

  rb_hash_aset(hash, rb_str_new2((const char *)name), notation);
}

static void element_copier(void *payload, void *data, xmlChar *name)
{
  VALUE hash = (VALUE)data;

  VALUE element = Nokogiri_wrap_xml_node((xmlNodePtr)payload);

  rb_hash_aset(hash, rb_str_new2((const char *)name), element);
}

/*
 * call-seq:
 *   entities
 *
 * Get a hash of the elements for this DTD.
 */
static VALUE entities(VALUE self)
{
  xmlDtdPtr dtd;
  Data_Get_Struct(self, xmlDtd, dtd);

  if(!dtd->entities) return Qnil;

  VALUE hash = rb_hash_new();

  xmlHashScan((xmlHashTablePtr)dtd->entities, element_copier, (void *)hash);

  return hash;
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

/*
 * call-seq:
 *   elements
 *
 * Get a hash of the elements for this DTD.
 */
static VALUE elements(VALUE self)
{
  xmlDtdPtr dtd;
  Data_Get_Struct(self, xmlDtd, dtd);

  if(!dtd->elements) return Qnil;

  VALUE hash = rb_hash_new();

  xmlHashScan((xmlHashTablePtr)dtd->elements, element_copier, (void *)hash);

  return hash;
}

void init_xml_dtd()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE node = rb_define_class_under(xml, "Node", rb_cObject);

  /*
   * Nokogiri::XML::DTD wraps DTD nodes in an XML document
   */
  VALUE klass = rb_define_class_under(xml, "DTD", node);

  rb_define_method(klass, "notations", notations, 0);
  rb_define_method(klass, "elements", elements, 0);
  rb_define_method(klass, "entities", entities, 0);
}
