#include <nokogiri.h>
#include <xmlsec_util.h>

static VALUE rb_set_id_attribute(VALUE self, VALUE rb_attr_name) {
  VALUE rb_exception_result = Qnil;
  const char* exception_message = NULL;

  xmlNodePtr node = NULL;
  xmlAttrPtr attr = NULL;
  xmlAttrPtr tmp = NULL;
  xmlChar *name = NULL;
  char *idName = NULL;
  char *exception_attribute_arg = NULL;

  resetXmlSecError();

  Noko_Node_Get_Struct(self, xmlNode, node);
  Check_Type(rb_attr_name, T_STRING);
  idName = StringValueCStr(rb_attr_name);

  // find pointer to id attribute
  attr = xmlHasProp(node, (const xmlChar* )idName);
  if((attr == NULL) || (attr->children == NULL)) {
    rb_exception_result = rb_eRuntimeError;
    exception_message = "Can't find attribute to add register as id";
    goto done;
  }

  // get the attribute (id) value
  name = xmlNodeListGetString(node->doc, attr->children, 1);
  if(name == NULL) {
    rb_exception_result = rb_eRuntimeError;
    exception_message = "has no value";
    exception_attribute_arg = idName;
    goto done;
  }

  // check that we don't have that id already registered
  tmp = xmlGetID(node->doc, name);
  if(tmp != NULL) {
    rb_exception_result = rb_eRuntimeError;
    exception_message = "is already an ID";
    exception_attribute_arg = idName;
    goto done;
  }

  // finally register id
  xmlAddID(NULL, node->doc, name, attr);

done:
  // and do not forget to cleanup
  if (name) {
    xmlFree(name);
  }

  xmlSecErrorsSetCallback(xmlSecErrorsDefaultCallback);

  if(rb_exception_result != Qnil) {
    if (exception_attribute_arg) {
      if (hasXmlSecLastError()) {
        rb_raise(rb_exception_result, "Attribute %s %s, XmlSec error: %s",
            exception_attribute_arg, exception_message, getXmlSecLastError());
      } else {
        rb_raise(rb_exception_result, "Attribute %s %s",
            exception_attribute_arg, exception_message);
      }
    } else {
      if (hasXmlSecLastError()) {
        rb_raise(rb_exception_result, "%s, XmlSec error: %s", exception_message,
                 getXmlSecLastError());
      } else {
        rb_raise(rb_exception_result, "%s", exception_message);
      }
    }
  }

  return Qtrue;
}

static VALUE rb_get_id(VALUE self, VALUE rb_id)
{
  xmlAttrPtr prop;
  xmlDocPtr doc;

  Check_Type(rb_id, T_STRING);
  Noko_Node_Get_Struct(self, xmlDoc, doc);
  prop = xmlGetID(doc, (const xmlChar *)StringValueCStr(rb_id));
  if (prop) {
    return noko_xml_node_wrap(Qnil, (xmlNodePtr)prop);
  } else {
    return Qnil;
  }
}

void
noko_xmlsec_init_id_attributes(void)
{
  rb_define_method(cNokogiriXmlsecDocument, "get_id", rb_get_id, 1);
  rb_define_method(cNokogiriXmlsecNode, "set_id_attribute", rb_set_id_attribute, 1);
}
