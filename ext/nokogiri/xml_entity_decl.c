#include <xml_entity_decl.h> 

/*
 * call-seq:
 *  original_content
 *
 * Get the original_content before ref substitution
 */
static VALUE original_content(VALUE self)
{
  xmlEntityPtr node;
  Data_Get_Struct(self, xmlEntity, node);

  if(!node->orig) return Qnil;

  return NOKOGIRI_STR_NEW2(node->orig);
}

/*
 * call-seq:
 *  content
 *
 * Get the content
 */
static VALUE get_content(VALUE self)
{
  xmlEntityPtr node;
  Data_Get_Struct(self, xmlEntity, node);

  if(!node->content) return Qnil;

  return NOKOGIRI_STR_NEW(node->content, node->length);
}

/*
 * call-seq:
 *  content
 *
 * Get the entity type
 */
static VALUE entity_type(VALUE self)
{
  xmlEntityPtr node;
  Data_Get_Struct(self, xmlEntity, node);

  return INT2NUM((int)node->etype);
}

/*
 * call-seq:
 *  external_id
 *
 * Get the external identifier for PUBLIC
 */
static VALUE external_id(VALUE self)
{
  xmlEntityPtr node;
  Data_Get_Struct(self, xmlEntity, node);

  if(!node->ExternalID) return Qnil;

  return NOKOGIRI_STR_NEW2(node->ExternalID);
}

/*
 * call-seq:
 *  system_id
 *
 * Get the URI for a SYSTEM or PUBLIC Entity
 */
static VALUE system_id(VALUE self)
{
  xmlEntityPtr node;
  Data_Get_Struct(self, xmlEntity, node);

  if(!node->SystemID) return Qnil;

  return NOKOGIRI_STR_NEW2(node->SystemID);
}

VALUE cNokogiriXmlEntityDecl;

void init_xml_entity_decl()
{
  VALUE nokogiri = rb_define_module("Nokogiri");
  VALUE xml = rb_define_module_under(nokogiri, "XML");
  VALUE node = rb_define_class_under(xml, "Node", rb_cObject);
  VALUE klass = rb_define_class_under(xml, "EntityDecl", node);

  cNokogiriXmlEntityDecl = klass;

  rb_define_method(klass, "original_content", original_content, 0);
  rb_define_method(klass, "content", get_content, 0);
  rb_define_method(klass, "entity_type", entity_type, 0);
  rb_define_method(klass, "external_id", external_id, 0);
  rb_define_method(klass, "system_id", system_id, 0);
}
