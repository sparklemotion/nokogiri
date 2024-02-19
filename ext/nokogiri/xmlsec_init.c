#include <nokogiri.h>

VALUE cNokogiriXmlsecDocument;
VALUE cNokogiriXmlsecNode;
VALUE cNokogiriXmlsecSigningError;
VALUE cNokogiriXmlsecVerificationError;
VALUE cNokogiriXmlsecKeystoreError;
VALUE cNokogiriXmlsecEncryptionError;
VALUE cNokogiriXmlsecDecryptionError;

void noko_xmlsec_init_decrypt_with_key(void);
void noko_xmlsec_init_encrypt_with_key(void);
void noko_xmlsec_init_id_attributes(void);
void noko_xmlsec_init_sign(void);
void noko_xmlsec_init_verify_with(void);

static void init_xmlsec_library(void);

void noko_init_xmlsec() {
  init_xmlsec_library();

  cNokogiriXmlsecDocument = rb_define_module_under(mNokogiriXmlsec, "Document");
  cNokogiriXmlsecNode = rb_define_module_under(mNokogiriXmlsec, "Node");

  cNokogiriXmlsecSigningError      = rb_define_class_under(mNokogiriXmlsec, "SigningError",      rb_eRuntimeError);
  cNokogiriXmlsecVerificationError = rb_define_class_under(mNokogiriXmlsec, "VerificationError", rb_eRuntimeError);
  cNokogiriXmlsecKeystoreError     = rb_define_class_under(mNokogiriXmlsec, "KeystoreError",     rb_eRuntimeError);
  cNokogiriXmlsecEncryptionError   = rb_define_class_under(mNokogiriXmlsec, "EncryptionError",   rb_eRuntimeError);
  cNokogiriXmlsecDecryptionError   = rb_define_class_under(mNokogiriXmlsec, "DecryptionError",   rb_eRuntimeError);

  noko_xmlsec_init_decrypt_with_key();
  noko_xmlsec_init_encrypt_with_key();
  noko_xmlsec_init_id_attributes();
  noko_xmlsec_init_sign();
  noko_xmlsec_init_verify_with();
}

static void init_xmlsec_library() {

  /* xmlsec proper */
  // libxml
  xmlLoadExtDtdDefaultValue = XML_DETECT_IDS | XML_COMPLETE_ATTRS;

  // // xmlsec

  if (xmlSecInit() < 0) {
    rb_raise(rb_eRuntimeError, "xmlsec initialization failed");
    return;
  }
  // Not sure why xmlsec thinks it should control this, but that's incompatible with a
  // being loaded in a general purpose library, so just reset it back to the default
  xmlSetExternalEntityLoader(NULL);
  if (xmlSecCheckVersion() != 1) {
    rb_raise(rb_eRuntimeError, "xmlsec version is not compatible");
    return;
  }
  // load crypto
  #ifdef XMLSEC_CRYPTO_DYNAMIC_LOADING
    if(xmlSecCryptoDLLoadLibrary(BAD_CAST XMLSEC_CRYPTO) < 0) {
      rb_raise(rb_eRuntimeError,
        "Error: unable to load default xmlsec-crypto library. Make sure"
        "that you have it installed and check shared libraries path\n"
        "(LD_LIBRARY_PATH) envornment variable.\n");
      return;
    }
  #endif /* XMLSEC_CRYPTO_DYNAMIC_LOADING */
  // init crypto
  if (xmlSecCryptoAppInit(NULL) < 0) {
    rb_raise(rb_eRuntimeError, "unable to initialize crypto engine");
    return;
  }
  // init xmlsec-crypto library
  if (xmlSecCryptoInit() < 0) {
    rb_raise(rb_eRuntimeError, "xmlsec-crypto initialization failed");
  }
}

