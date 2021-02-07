#include <nokogiri.h>

VALUE cNokogiriXmlDtd;
static VALUE cNokogiriXmlNotation = 0;

static void
notation_copier(void *payload, void *data, const xmlChar *name)
{
  VALUE hash = (VALUE)data;

  xmlNotationPtr c_notation = (xmlNotationPtr)payload;
  VALUE notation;
  VALUE argv[3];
  argv[0] = (c_notation->name ? NOKOGIRI_STR_NEW2(c_notation->name) : Qnil);
  argv[1] = (c_notation->PublicID ? NOKOGIRI_STR_NEW2(c_notation->PublicID) : Qnil);
  argv[2] = (c_notation->SystemID ? NOKOGIRI_STR_NEW2(c_notation->SystemID) : Qnil);

  if (!cNokogiriXmlNotation) {
    cNokogiriXmlNotation = rb_const_get_at(mNokogiriXml, rb_intern("Notation"));
  }
  notation = rb_class_new_instance(3, argv, cNokogiriXmlNotation);

  rb_hash_aset(hash, NOKOGIRI_STR_NEW2(name), notation);
}

static void
element_copier(void *_payload, void *data, const xmlChar *name)
{
  VALUE hash = (VALUE)data;
  xmlNodePtr payload = (xmlNodePtr)_payload;

  VALUE element = noko_xml_node_wrap(Qnil, payload);

  rb_hash_aset(hash, NOKOGIRI_STR_NEW2(name), element);
}

/*
 * call-seq:
 *   entities
 *
 * Get a hash of the elements for this DTD.
 */
static VALUE
entities(VALUE self)
{
  xmlDtdPtr dtd;
  VALUE hash;

  Data_Get_Struct(self, xmlDtd, dtd);

  if (!dtd->entities) { return Qnil; }

  hash = rb_hash_new();

  xmlHashScan((xmlHashTablePtr)dtd->entities, element_copier, (void *)hash);

  return hash;
}

/*
 * call-seq:
 *   notations
 *
 * Get a hash of the notations for this DTD.
 */
static VALUE
notations(VALUE self)
{
  xmlDtdPtr dtd;
  VALUE hash;

  Data_Get_Struct(self, xmlDtd, dtd);

  if (!dtd->notations) { return Qnil; }

  hash = rb_hash_new();

  xmlHashScan((xmlHashTablePtr)dtd->notations, notation_copier, (void *)hash);

  return hash;
}

/*
 * call-seq:
 *   attributes
 *
 * Get a hash of the attributes for this DTD.
 */
static VALUE
attributes(VALUE self)
{
  xmlDtdPtr dtd;
  VALUE hash;

  Data_Get_Struct(self, xmlDtd, dtd);

  hash = rb_hash_new();

  if (!dtd->attributes) { return hash; }

  xmlHashScan((xmlHashTablePtr)dtd->attributes, element_copier, (void *)hash);

  return hash;
}

/*
 * call-seq:
 *   elements
 *
 * Get a hash of the elements for this DTD.
 */
static VALUE
elements(VALUE self)
{
  xmlDtdPtr dtd;
  VALUE hash;

  Data_Get_Struct(self, xmlDtd, dtd);

  if (!dtd->elements) { return Qnil; }

  hash = rb_hash_new();

  xmlHashScan((xmlHashTablePtr)dtd->elements, element_copier, (void *)hash);

  return hash;
}

/*
 * call-seq:
 *   validate(document)
 *
 * Validate +document+ returning a list of errors
 */
static VALUE
validate(VALUE self, VALUE document)
{
  xmlDocPtr doc;
  xmlDtdPtr dtd;
  xmlValidCtxtPtr ctxt;
  VALUE error_list;

  Data_Get_Struct(self, xmlDtd, dtd);
  Data_Get_Struct(document, xmlDoc, doc);
  error_list = rb_ary_new();

  ctxt = xmlNewValidCtxt();

  xmlSetStructuredErrorFunc((void *)error_list, Nokogiri_error_array_pusher);

  xmlValidateDtd(ctxt, doc, dtd);

  xmlSetStructuredErrorFunc(NULL, NULL);

  xmlFreeValidCtxt(ctxt);

  return error_list;
}

/*
 * call-seq:
 *   system_id
 *
 * Get the System ID for this DTD
 */
static VALUE
system_id(VALUE self)
{
  xmlDtdPtr dtd;
  Data_Get_Struct(self, xmlDtd, dtd);

  if (!dtd->SystemID) { return Qnil; }

  return NOKOGIRI_STR_NEW2(dtd->SystemID);
}

/*
 * call-seq:
 *   external_id
 *
 * Get the External ID for this DTD
 */
static VALUE
external_id(VALUE self)
{
  xmlDtdPtr dtd;
  Data_Get_Struct(self, xmlDtd, dtd);

  if (!dtd->ExternalID) { return Qnil; }

  return NOKOGIRI_STR_NEW2(dtd->ExternalID);
}

void
noko_init_xml_dtd()
{
  assert(cNokogiriXmlNode);
  /*
   * Nokogiri::XML::DTD wraps DTD nodes in an XML document
   */
  cNokogiriXmlDtd = rb_define_class_under(mNokogiriXml, "DTD", cNokogiriXmlNode);

  rb_define_method(cNokogiriXmlDtd, "notations", notations, 0);
  rb_define_method(cNokogiriXmlDtd, "elements", elements, 0);
  rb_define_method(cNokogiriXmlDtd, "entities", entities, 0);
  rb_define_method(cNokogiriXmlDtd, "validate", validate, 1);
  rb_define_method(cNokogiriXmlDtd, "attributes", attributes, 0);
  rb_define_method(cNokogiriXmlDtd, "system_id", system_id, 0);
  rb_define_method(cNokogiriXmlDtd, "external_id", external_id, 0);
}
