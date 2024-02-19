#include <nokogiri.h>
#include <xmlsec_options.h>
#include <xmlsec_util.h>

// Encrypes the XML Document document using XMLEnc.
//
// Expects 3 positional arguments:
//   rb_rsa_key_name - String with name of the rsa key. May be the empty.
//   rb_rsa_key - A PEM encoded rsa key for signing.
//   rb_opts - An ruby hash that configures the encryption options.
//             See XmlEncOptions struct for possible values.
static VALUE rb_encrypt_with_key(VALUE self, VALUE rb_rsa_key_name, VALUE rb_rsa_key,
                       VALUE rb_opts) {
  VALUE rb_exception_result = Qnil;
  VALUE rb_cert = Qnil;
  const char* exception_message = NULL;

  xmlDocPtr doc = NULL;
  xmlNodePtr node = NULL;
  xmlNodePtr encDataNode = NULL;
  xmlNodePtr encKeyNode  = NULL;
  xmlNodePtr keyInfoNode = NULL;
  xmlSecEncCtxPtr encCtx = NULL;
  xmlSecKeysMngrPtr keyManager = NULL;
  char *keyName = NULL;
  char *key = NULL;
  char *certificate = NULL;
  unsigned int keyLength = 0;
  unsigned int certificateLength = 0;

  resetXmlSecError();

  Check_Type(rb_rsa_key,      T_STRING);
  Check_Type(rb_opts, T_HASH);

  key       = RSTRING_PTR(rb_rsa_key);
  keyLength = RSTRING_LEN(rb_rsa_key);
  if (rb_rsa_key_name != Qnil) {
    Check_Type(rb_rsa_key_name, T_STRING);
    keyName = StringValueCStr(rb_rsa_key_name);
  }

  rb_cert = rb_hash_aref(rb_opts, ID2SYM(rb_intern("cert")));
  if (!NIL_P(rb_cert)) {
    Check_Type(rb_cert, T_STRING);
    certificate = RSTRING_PTR(rb_cert);
    certificateLength = RSTRING_LEN(rb_cert);
  }

  XmlEncOptions options;
  if (!GetXmlEncOptions(rb_opts, &options, &rb_exception_result,
                        &exception_message)) {
    goto done;
  }

  Noko_Node_Get_Struct(self, xmlNode, node);
  doc = node->doc;

  // create encryption template to encrypt XML file and replace 
  // its content with encryption result
  encDataNode = xmlSecTmplEncDataCreate(doc, options.block_encryption, NULL,
                                        xmlSecTypeEncElement, NULL, NULL);
  if(encDataNode == NULL) {
    rb_exception_result = cNokogiriXmlsecEncryptionError;
    exception_message = "failed to create encryption template";
    goto done;
  }

  // we want to put encrypted data in the <enc:CipherValue/> node
  if(xmlSecTmplEncDataEnsureCipherValue(encDataNode) == NULL) {
    rb_exception_result = cNokogiriXmlsecEncryptionError;
    exception_message = "failed to add CipherValue node";
    goto done;
  }

  // add <dsig:KeyInfo/> and <dsig:KeyName/> nodes to put key name in the
  // signed document
  keyInfoNode = xmlSecTmplEncDataEnsureKeyInfo(encDataNode, NULL);
  if(keyInfoNode == NULL) {
    rb_exception_result = cNokogiriXmlsecEncryptionError;
    exception_message = "failed to add key info";
    goto done;
  }

  if(certificate) {
    // add <dsig:X509Data/>
    if(xmlSecTmplKeyInfoAddX509Data(keyInfoNode) == NULL) {
      rb_exception_result = cNokogiriXmlsecSigningError;
      exception_message = "failed to add X509Data node";
      goto done;
    }
  }

  if(keyName != NULL) {
    if(xmlSecTmplKeyInfoAddKeyName(keyInfoNode, keyName) == NULL) {
      rb_exception_result = cNokogiriXmlsecEncryptionError;
      exception_message = "failed to add key name";
      goto done;
    }
  }

  if ((keyManager = createKeyManagerWithSingleKey(
          key, keyLength, keyName,
          &rb_exception_result,
          &exception_message)) == NULL) {
    // Propagate the exception.
    goto done;
  }

  // create encryption context, we don't need keys manager in this example
  encCtx = xmlSecEncCtxCreate(keyManager);
  if(encCtx == NULL) {
    rb_exception_result = cNokogiriXmlsecEncryptionError;
    exception_message = "failed to create encryption context";
    goto done;
  }

  // Generate the symmetric key.
  encCtx->encKey = xmlSecKeyGenerateByName(BAD_CAST options.key_type, options.key_bits,
                                           xmlSecKeyDataTypeSession);

  if(encCtx->encKey == NULL) {
    rb_exception_result = cNokogiriXmlsecDecryptionError;
    exception_message = "failed to generate session key";
    goto done;
  }

  if(certificate) {
    // load certificate and add to the key
    if(xmlSecCryptoAppKeyCertLoadMemory(encCtx->encKey,
                                        (xmlSecByte *)certificate,
                                        certificateLength,
                                        xmlSecKeyDataFormatPem) < 0) {
      rb_exception_result = cNokogiriXmlsecSigningError;
      exception_message = "failed to load certificate";
      goto done;
    }
  }

  // Set key name.
  if(keyName) {
    if(xmlSecKeySetName(encCtx->encKey, (xmlSecByte *)keyName) < 0) {
      rb_exception_result = cNokogiriXmlsecEncryptionError;
      exception_message = "failed to set key name";
      goto done;
    }
  }

  // Add <enc:EncryptedKey/> node to the <dsig:KeyInfo/> tag to include
  // the session key.
  encKeyNode = xmlSecTmplKeyInfoAddEncryptedKey(keyInfoNode,
                                       options.key_transport, // encMethodId encryptionMethod
                                       NULL, // xmlChar *idAttribute
                                       NULL, // xmlChar *typeAttribute
                                       NULL  // xmlChar *recipient
                                      );

  if (encKeyNode == NULL) {
    rb_exception_result = cNokogiriXmlsecEncryptionError;
    exception_message = "failed to add encrypted key node";
    goto done;
  }
  if (xmlSecTmplEncDataEnsureCipherValue(encKeyNode) == NULL) {
    rb_exception_result = cNokogiriXmlsecEncryptionError;
    exception_message = "failed to add encrypted cipher value";
    goto done;
  }
  // don't let xmlsec free the node we're looking at out from under us
  encCtx->flags |= XMLSEC_ENC_RETURN_REPLACED_NODE;

  encCtx->keyInfoReadCtx.flags |= XMLSEC_KEYINFO_FLAGS_LAX_KEY_SEARCH;
  encCtx->keyInfoWriteCtx.flags |= XMLSEC_KEYINFO_FLAGS_LAX_KEY_SEARCH;

  // encrypt the data
  if(xmlSecEncCtxXmlEncrypt(encCtx, encDataNode, node) < 0) {
    rb_exception_result = cNokogiriXmlsecEncryptionError;
    exception_message = "encryption failed";
    goto done;
  }
  
  // the template is inserted in the doc, so don't free it
  encDataNode = NULL;
  encKeyNode = NULL;

done:
  // cleanup
  if(encCtx != NULL) {
    // the replaced node is orphaned, but not freed; let Nokogiri
    // own it now
    if(encCtx->replacedNodeList != NULL) {
      noko_xml_document_pin_node(encCtx->replacedNodeList);
      // no really, please don't free it
      encCtx->replacedNodeList = NULL;
    }
    xmlSecEncCtxDestroy(encCtx);
  }

  if (encKeyNode != NULL) {
    xmlFreeNode(encKeyNode);
  }

  if(encDataNode != NULL) {
    xmlFreeNode(encDataNode);
  }

  if (keyManager != NULL) {
    xmlSecKeysMngrDestroy(keyManager);
  }

  xmlSecErrorsSetCallback(xmlSecErrorsDefaultCallback);

  if(rb_exception_result != Qnil) {
    if (hasXmlSecLastError()) {
      rb_raise(rb_exception_result, "%s, XmlSec error: %s", exception_message,
               getXmlSecLastError());
    } else {
      rb_raise(rb_exception_result, "%s", exception_message);
    }
  }

  return Qnil;
}

void
noko_xmlsec_init_encrypt_with_key(void)
{
  rb_define_method(cNokogiriXmlsecNode, "encrypt_with_key", rb_encrypt_with_key, 3);
}
