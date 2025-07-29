#include <nokogiri.h>

#include <xmlsec/app.h>
#include <xmlsec/crypto.h>
#include <xmlsec/keysmngr.h>

VALUE cNokogiriXmlSecurityKeysManager = Qnil;

static ID id_to_pem;

NORETURN_DECL void noko_xml_security_error_s_raise(const char *exception_message);

static void
dealloc(void *ptr)
{
  xmlSecKeysMngrPtr keysMngr = (xmlSecKeysMngrPtr)ptr;
  if (keysMngr) {
    xmlSecKeysMngrDestroy(keysMngr);
  }
}

static const rb_data_type_t xml_security_keys_manager_type = {
  .wrap_struct_name = "xmlSecurityKeysManager",
  .function = {
    .dfree = dealloc,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

void
Noko_XML_Security_Get_Struct(VALUE value, xmlSecKeysMngrPtr *keysMngr)
{
  TypedData_Get_Struct(value, xmlSecKeysMngr, &xml_security_keys_manager_type, *keysMngr);
}

VALUE
xmlsec_obj_as_pem_string(VALUE rb_obj)
{
  if (!RB_UNDEF_P(rb_check_funcall(rb_obj, id_to_pem, 0, NULL))) {
    rb_obj = rb_funcall(rb_obj, id_to_pem, 0, NULL);
  }
  StringValue(rb_obj);
  return rb_obj;
}

static VALUE
noko_xml_security_keys_manager_s_new(VALUE self)
{
  VALUE rb_keys_manager;
  xmlSecKeysMngrPtr keysMngr = xmlSecKeysMngrCreate();
  if (keysMngr == NULL) {
    noko_xml_security_error_s_raise("Failed to create XML Security Keys Manager");
  }
  rb_keys_manager = TypedData_Wrap_Struct(cNokogiriXmlSecurityKeysManager, &xml_security_keys_manager_type, keysMngr);

  if (xmlSecCryptoAppDefaultKeysMngrInit(keysMngr) < 0) {
    noko_xml_security_error_s_raise("Could not initialize key manager");
  }

  rb_obj_call_init(rb_keys_manager, 0, NULL);
  return rb_keys_manager;
}

static VALUE
noko_xml_security_keys_manager__add_key(VALUE self, VALUE rb_name, VALUE rb_key)
{
  xmlSecKeysMngrPtr keysMngr;
  const char *key_name = NULL;

  Noko_Node_Get_Struct(self, xmlSecKeysMngr, keysMngr);

  key_name = StringValueCStr(rb_name);
  rb_key = xmlsec_obj_as_pem_string(rb_key);

  xmlSecKeyPtr key = xmlSecCryptoAppKeyLoadMemory((xmlSecByte *)RSTRING_PTR(rb_key),
                     (size_t)RSTRING_LEN(rb_key),
                     xmlSecKeyDataFormatPem,
                     NULL, // password
                     NULL, NULL);
  if (key == NULL) {
    noko_xml_security_error_s_raise("Failed to load key");
  }

  if (xmlSecKeySetName(key, (const xmlChar *)key_name) < 0) {
    xmlSecKeyDestroy(key);
    noko_xml_security_error_s_raise("Failed to set key name");
  }

  // add key to key manager; from now on the manager is responsible for
  // destroying the key
  if (xmlSecCryptoAppDefaultKeysMngrAdoptKey(keysMngr, key) < 0) {
    xmlSecKeyDestroy(key);
    noko_xml_security_error_s_raise("Failed to add key to key manager");
  }

  return self;
}

static VALUE
noko_xml_security_keys_manager__add_certificate(VALUE self, VALUE rb_certificate)
{
  xmlSecKeysMngrPtr keysMngr;

  Noko_Node_Get_Struct(self, xmlSecKeysMngr, keysMngr);

  rb_certificate = xmlsec_obj_as_pem_string(rb_certificate);

  if (xmlSecCryptoAppKeysMngrCertLoadMemory(keysMngr,
      (xmlSecByte *)RSTRING_PTR(rb_certificate),
      (size_t)RSTRING_LEN(rb_certificate),
      xmlSecKeyDataFormatPem,
      xmlSecKeyDataTypeTrusted) < 0) {
    noko_xml_security_error_s_raise("Could not add certificate to keys manager");
  }

  return self;
}

void
noko_init_xml_security_keys_manager(void)
{
  assert(NokogiriXmlSecurity);

  cNokogiriXmlSecurityKeysManager = rb_define_class_under(mNokogiriXmlSecurity, "KeysManager", rb_cObject);

  rb_undef_alloc_func(cNokogiriXmlSecurityKeysManager);

  rb_define_singleton_method(cNokogiriXmlSecurityKeysManager, "new", noko_xml_security_keys_manager_s_new, 0);

  rb_define_method(cNokogiriXmlSecurityKeysManager, "add_key", noko_xml_security_keys_manager__add_key, 2);
  rb_define_method(cNokogiriXmlSecurityKeysManager, "add_certificate", noko_xml_security_keys_manager__add_certificate,
                   1);

  id_to_pem = rb_intern("to_pem");
}
