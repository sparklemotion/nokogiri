
#include <nokogiri.h>

#include <xmlsec/xmlsec.h>
#include <xmlsec/crypto.h>
#include <xmlsec/dl.h>
#include <xmlsec/errors.h>
#include <xmlsec/templates.h>
#include <xmlsec/xmldsig.h>
#include <xmlsec/xmlenc.h>
#include <xmlsec/xmltree.h>

#ifndef XMLSEC_NO_XSLT
#include <libxslt/xslt.h>
#include <libxslt/security.h>
#endif

NORETURN_DECL void noko_xml_security_error_s_raise(const char *exception_message);
void Noko_XML_Security_Get_Struct(VALUE value, xmlSecKeysMngrPtr *keysMngr);
VALUE xmlsec_obj_as_pem_string(VALUE rb_obj);

#if (XMLSEC_VERSION_MAJOR > 1) || (XMLSEC_VERSION_MAJOR == 1 && (XMLSEC_VERSION_MINOR > 2 || (XMLSEC_VERSION_MINOR == 2 && XMLSEC_VERSION_SUBMINOR >= 20)))
# define HAS_ECDSA
#endif

void xmlsec_reset_last_error(void);
void noko_xml_xmlsec_error_s_raise(const char *);

static
xmlSecDSigCtxPtr
xmlsec_create_dsig_context(xmlSecKeysMngrPtr keysMngr)
{
  xmlSecDSigCtxPtr dsigCtx = xmlSecDSigCtxCreate(keysMngr);
  if (!dsigCtx) {
    return NULL;
  }

  // Restrict ReferenceUris to same document or empty to avoid XXE attacks.
  dsigCtx->enabledReferenceUris = xmlSecTransformUriTypeEmpty |
                                  xmlSecTransformUriTypeSameDocument;

  return dsigCtx;
}


// Supported signature algorithms taken from #6 of
// http://www.w3.org/TR/xmldsig-core1/
static const char RSA_SHA1[] = "rsa-sha1";
static const char RSA_SHA224[] = "rsa-sha224";
static const char RSA_SHA256[] = "rsa-sha256";
static const char RSA_SHA384[] = "rsa-sha384";
static const char RSA_SHA512[] = "rsa-sha512";
static const char DSA_SHA1[] = "dsa-sha1";

#ifdef HAS_ECDSA
static const char ECDSA_SHA1[] = "ecdsa-sha1";
static const char ECDSA_SHA224[] = "ecdsa-sha224";
static const char ECDSA_SHA256[] = "ecdsa-sha256";
static const char ECDSA_SHA384[] = "ecdsa-sha384";
static const char ECDSA_SHA512[] = "ecdsa-sha512";
static const char DSA_SHA256[] = "dsa-sha256";
#endif  // HAS_ECDSA

static
xmlSecTransformId
xmlsec_get_signature_method(VALUE rb_signature_alg)
{
  const char *signature_algorithm = RSTRING_PTR(rb_signature_alg);
  size_t signature_algorithm_len = (size_t)RSTRING_LEN(rb_signature_alg);

  if (strncmp(RSA_SHA1, signature_algorithm, signature_algorithm_len) == 0) {
    return xmlSecTransformRsaSha1Id;
  } else if (strncmp(RSA_SHA224, signature_algorithm, signature_algorithm_len) == 0) {
    return xmlSecTransformRsaSha224Id;
  } else if (strncmp(RSA_SHA256, signature_algorithm, signature_algorithm_len) == 0) {
    return xmlSecTransformRsaSha256Id;
  } else if (strncmp(RSA_SHA384, signature_algorithm, signature_algorithm_len) == 0) {
    return xmlSecTransformRsaSha384Id;
  } else if (strncmp(RSA_SHA512, signature_algorithm, signature_algorithm_len) == 0) {
    return xmlSecTransformRsaSha512Id;

  }
#ifdef HAS_ECDSA
  else if (strncmp(ECDSA_SHA1, signature_algorithm, signature_algorithm_len) == 0) {
    return xmlSecTransformEcdsaSha1Id;
  } else if (strncmp(ECDSA_SHA224, signature_algorithm, signature_algorithm_len) == 0) {
    return xmlSecTransformEcdsaSha224Id;
  } else if (strncmp(ECDSA_SHA256, signature_algorithm, signature_algorithm_len) == 0) {
    return xmlSecTransformEcdsaSha256Id;
  } else if (strncmp(ECDSA_SHA384, signature_algorithm, signature_algorithm_len) == 0) {
    return xmlSecTransformEcdsaSha384Id;
  } else if (strncmp(ECDSA_SHA512, signature_algorithm, signature_algorithm_len) == 0) {
    return xmlSecTransformEcdsaSha512Id;
  } else if (strncmp(DSA_SHA1, signature_algorithm, signature_algorithm_len) == 0) {
    return xmlSecTransformDsaSha1Id;
  } else if (strncmp(DSA_SHA256, signature_algorithm, signature_algorithm_len) == 0) {
    return xmlSecTransformDsaSha256Id;
  }
#endif  // HAS_ECDSA

  rb_raise(rb_eArgError, "Unknown signature_algorithm %.*s", (int)signature_algorithm_len, signature_algorithm);
}

// Supported digest algorithms taken from #6 of
// http://www.w3.org/TR/xmldsig-core1/
static const char DIGEST_SHA1[] = "sha1";
static const char DIGEST_SHA224[] = "sha224";
static const char DIGEST_SHA256[] = "sha256";
static const char DIGEST_SHA384[] = "sha384";
static const char DIGEST_SHA512[] = "sha512";


static
xmlSecTransformId
xmlsec_get_digest_method(VALUE rb_digest_alg)
{
  const char *digest_algorithm = RSTRING_PTR(rb_digest_alg);
  size_t digest_algorithm_len = (size_t)RSTRING_LEN(rb_digest_alg);

  if (strncmp(DIGEST_SHA1, digest_algorithm, digest_algorithm_len) == 0) {
    return xmlSecTransformSha1Id;
  } else if (strncmp(DIGEST_SHA224, digest_algorithm, digest_algorithm_len) == 0) {
    return xmlSecTransformSha224Id;
  } else if (strncmp(DIGEST_SHA256, digest_algorithm, digest_algorithm_len) == 0) {
    return xmlSecTransformSha256Id;
  } else if (strncmp(DIGEST_SHA384, digest_algorithm, digest_algorithm_len) == 0) {
    return xmlSecTransformSha384Id;
  } else if (strncmp(DIGEST_SHA512, digest_algorithm, digest_algorithm_len) == 0) {
    return xmlSecTransformSha512Id;
  }

  rb_raise(rb_eArgError, "Unknown digest_algorithm %.*s", (int)digest_algorithm_len, digest_algorithm);
}

// Canonicalization algorithms
// http://www.w3.org/TR/xmldsig-core1/#sec-Canonicalization
static const char C14N[] = "c14n";
static const char C14N_WITH_COMMENTS[] = "c14n-with-comments";
static const char EXCL_C14N[] = "exc-c14n";
static const char EXCL_C14N_WITH_COMMENTS[] = "exc-c14n-with-comments";

static
xmlSecTransformId
xmlsec_get_canonicalization_method(VALUE rb_canonicalization_algorithm)
{
  const char *canonicalization_algorithm = RSTRING_PTR(rb_canonicalization_algorithm);
  size_t canonicalization_algorithm_len = (size_t)RSTRING_LEN(rb_canonicalization_algorithm);

  if (strncmp(C14N, canonicalization_algorithm, canonicalization_algorithm_len) == 0) {
    return xmlSecTransformInclC14NId;
  } else if (strncmp(C14N_WITH_COMMENTS, canonicalization_algorithm, canonicalization_algorithm_len) == 0) {
    return xmlSecTransformInclC14NWithCommentsId;
  } else if (strncmp(EXCL_C14N, canonicalization_algorithm, canonicalization_algorithm_len) == 0) {
    return xmlSecTransformExclC14NId;
  } else if (strncmp(EXCL_C14N_WITH_COMMENTS, canonicalization_algorithm, canonicalization_algorithm_len) == 0) {
    return xmlSecTransformExclC14NWithCommentsId;
  }

  rb_raise(rb_eArgError, "Unknown canonicalization algorithm %.*s", (int)canonicalization_algorithm_len,
           canonicalization_algorithm);
}

// Block Encryption Strings
static const char TRIPLEDES_CBC[] = "tripledes-cbc";
static const char AES128_CBC[] = "aes128-cbc";
static const char AES256_CBC[] = "aes256-cbc";
static const char AES192_CBC[] = "aes192-cbc";

static
xmlSecTransformId
xmlsec_get_block_encryption_method(VALUE rb_block_encryption_algorithm,
                                   const char **key_type,
                                   size_t *key_bits)
{
  const char *block_encryption_algorithm = RSTRING_PTR(rb_block_encryption_algorithm);
  size_t block_encryption_algorithm_len = (size_t)RSTRING_LEN(rb_block_encryption_algorithm);

  if (strncmp(AES256_CBC, block_encryption_algorithm, block_encryption_algorithm_len) == 0) {
    *key_type = "aes";
    *key_bits = 256;
    return xmlSecTransformAes256CbcId;
  } else if (strncmp(AES128_CBC, block_encryption_algorithm, block_encryption_algorithm_len) == 0) {
    *key_type = "aes";
    *key_bits = 128;
    return xmlSecTransformAes128CbcId;
  } else if (strncmp(AES192_CBC, block_encryption_algorithm, block_encryption_algorithm_len) == 0) {
    *key_type = "aes";
    *key_bits = 192;
    return xmlSecTransformAes192CbcId;
  } else if (strncmp(TRIPLEDES_CBC, block_encryption_algorithm, block_encryption_algorithm_len) == 0) {
    *key_type = "des";
    *key_bits = 192;
    return xmlSecTransformDes3CbcId;
  }

  rb_raise(rb_eArgError, "Unknown block_encryption %.*s", (int)block_encryption_algorithm_len,
           block_encryption_algorithm);
}

// Key Transport Strings
static const char RSA1_5[] = "rsa-1_5";
static const char RSA_OAEP_MGF1P[] = "rsa-oaep-mgf1p";

static
xmlSecTransformId
xmlsec_get_key_transport_method(VALUE rb_key_transport_algorithm)
{
  const char *key_transport_value = RSTRING_PTR(rb_key_transport_algorithm);
  size_t key_transport_len = (size_t)RSTRING_LEN(rb_key_transport_algorithm);

  if (strncmp(RSA1_5, key_transport_value, key_transport_len) == 0) {
    return xmlSecTransformRsaPkcs1Id;
  } else if (strncmp(RSA_OAEP_MGF1P, key_transport_value, key_transport_len) == 0) {
    return xmlSecTransformRsaOaepId;
  }


  rb_raise(rb_eArgError, "Unknown key_transport %.*s", (int)key_transport_len, key_transport_value);
}

VALUE
noko_xml_node__native_decrypt(VALUE self, VALUE rb_keys_manager)
{
  xmlNodePtr node = NULL, previous_sibling = NULL, parent = NULL;
  xmlSecEncCtxPtr encCtx = NULL;
  xmlSecKeysMngrPtr keysMngr = NULL;

  xmlsec_reset_last_error();

  Noko_Node_Get_Struct(self, xmlNode, node);
  Noko_XML_Security_Get_Struct(rb_keys_manager, &keysMngr);

  previous_sibling = xmlPreviousElementSibling(node);
  parent = node->parent;

  // create encryption context
  encCtx = xmlSecEncCtxCreate(keysMngr);
  if (encCtx == NULL) {
    noko_xml_security_error_s_raise("Failed to create encryption context");
  }
  // don't let xmlsec free the node we're looking at out from under us
  encCtx->flags |= XMLSEC_ENC_RETURN_REPLACED_NODE;

#ifdef XMLSEC_KEYINFO_FLAGS_LAX_KEY_SEARCH
  // Enable lax key search, since xmlsec 1.3.0
  encCtx->keyInfoReadCtx.flags |= XMLSEC_KEYINFO_FLAGS_LAX_KEY_SEARCH;
#endif

  // decrypt the data
  if ((xmlSecEncCtxDecrypt(encCtx, node) < 0) || (encCtx->result == NULL)) {
    xmlSecEncCtxDestroy(encCtx);
    noko_xml_security_error_s_raise("Failed to decrypt data");
  }

  if (encCtx->resultReplaced == 0) {
    xmlSecEncCtxDestroy(encCtx);
    rb_raise(rb_eNotImpError, "Decrypted, non-XML data is not yet supported.");
  }

  // the replaced node is orphaned, but not freed; let Nokogiri
  // own it now
  if (encCtx->replacedNodeList != NULL) {
    noko_xml_document_pin_node(encCtx->replacedNodeList);
    // no really, please don't free it
    encCtx->replacedNodeList = NULL;
  }
  xmlSecEncCtxDestroy(encCtx);

  if (previous_sibling != NULL) {
    node = xmlNextElementSibling(previous_sibling);
    if (!node) {
      return Qnil;
    }
    return noko_xml_node_wrap(Qnil, node);
  } else {
    node = xmlFirstElementChild(parent);
    if (!node) {
      return Qnil;
    }
    return noko_xml_node_wrap(Qnil, node);
  }
}

VALUE
noko_xml_node__native_encrypt(VALUE self,
                              VALUE rb_keys_manager,
                              VALUE rb_key_name,
                              VALUE rb_certificate,
                              VALUE rb_block_encryption,
                              VALUE rb_key_transport)
{
  const char *key_type = NULL, *key_name = NULL;
  size_t key_bits = 0;
  xmlDocPtr doc = NULL;
  xmlNodePtr node = NULL;
  xmlNodePtr encryptedData_node = NULL;
  xmlNodePtr encryptedKey_node  = NULL;
  xmlNodePtr keyInfo_node = NULL;
  xmlSecEncCtxPtr encCtx = NULL;
  xmlSecTransformId block_encryption, key_transport;
  xmlSecKeysMngrPtr keysMngr = NULL;

  xmlsec_reset_last_error();

  Noko_XML_Security_Get_Struct(rb_keys_manager, &keysMngr);
  Noko_Node_Get_Struct(self, xmlNode, node);
  doc = node->doc;

  StringValue(rb_block_encryption);
  StringValue(rb_key_transport);

  if (!NIL_P(rb_certificate)) {
    StringValue(rb_certificate);
  }
  if (!NIL_P(rb_key_name)) {
    key_name = StringValueCStr(rb_key_name);
  }

  block_encryption = xmlsec_get_block_encryption_method(rb_block_encryption,
                     &key_type, &key_bits);

  key_transport = xmlsec_get_key_transport_method(rb_key_transport);

  // create encryption template to encrypt XML file and replace
  // its content with encryption result
  encryptedData_node = xmlSecTmplEncDataCreate(doc, block_encryption, NULL,
                       xmlSecTypeEncElement, NULL, NULL);
  if (encryptedData_node == NULL) {
    noko_xml_security_error_s_raise("Failed to create encryption template");
  }
  // we want to put encrypted data in the <enc:CipherValue/> node
  if (xmlSecTmplEncDataEnsureCipherValue(encryptedData_node) == NULL) {
    xmlFreeNode(encryptedData_node);
    noko_xml_security_error_s_raise("Failed to add CipherValue node");
  }

  // add <dsig:KeyInfo/> and <dsig:KeyName/> nodes to put key name in the
  // signed document
  keyInfo_node = xmlSecTmplEncDataEnsureKeyInfo(encryptedData_node, NULL);
  if (keyInfo_node == NULL) {
    xmlFreeNode(encryptedData_node);
    noko_xml_security_error_s_raise("Failed to add key info");
  }

  if (!NIL_P(rb_certificate)) {
    // add <dsig:X509Data/>
    if (xmlSecTmplKeyInfoAddX509Data(keyInfo_node) == NULL) {
      xmlFreeNode(encryptedData_node);
      noko_xml_security_error_s_raise("Failed to add X509Data node");
    }
  }

  if (key_name) {
    if (xmlSecTmplKeyInfoAddKeyName(keyInfo_node, NULL) == NULL) {
      xmlFreeNode(encryptedData_node);
      noko_xml_security_error_s_raise("Failed to add key name");
    }
  }

  // Add <enc:EncryptedKey/> node to the <dsig:KeyInfo/> tag to include
  // the session key.
  encryptedKey_node = xmlSecTmplKeyInfoAddEncryptedKey(keyInfo_node,
                      key_transport, // encMethodId encryptionMethod
                      NULL, // xmlChar *idAttribute
                      NULL, // xmlChar *typeAttribute
                      NULL  // xmlChar *recipient
                                                      );
  if (encryptedKey_node == NULL) {
    xmlFreeNode(encryptedData_node);
    noko_xml_security_error_s_raise("Failed to add encrypted key node");
  }
  if (xmlSecTmplEncDataEnsureCipherValue(encryptedKey_node) == NULL) {
    xmlFreeNode(encryptedData_node);
    noko_xml_security_error_s_raise("Failed to add encrypted cipher value");
  }

  encCtx = xmlSecEncCtxCreate(keysMngr);
  if (encCtx == NULL) {
    xmlFreeNode(encryptedData_node);
    noko_xml_security_error_s_raise("Failed to create encryption context");
  }

#ifdef XMLSEC_KEYINFO_FLAGS_LAX_KEY_SEARCH
  // Enable lax key search, since xmlsec 1.3.0
  encCtx->keyInfoWriteCtx.flags |= XMLSEC_KEYINFO_FLAGS_LAX_KEY_SEARCH;
#endif

  // We don't want xmlsec to free the node we're looking at out from under us,
  // since it's still referenced from a Ruby object.
  encCtx->flags |= XMLSEC_ENC_RETURN_REPLACED_NODE;

  // Generate the symmetric session key
  encCtx->encKey = xmlSecKeyGenerateByName((const xmlChar *)key_type, key_bits,
                   xmlSecKeyDataTypeSession);

  if (encCtx->encKey == NULL) {
    xmlSecEncCtxDestroy(encCtx);
    xmlFreeNode(encryptedData_node);
    noko_xml_security_error_s_raise("Failed to generate session key");
  }

  if (!NIL_P(rb_certificate)) {
    // load certificate and add to the key
    if (xmlSecCryptoAppKeyCertLoadMemory(encCtx->encKey,
                                         (xmlSecByte *)RSTRING_PTR(rb_certificate),
                                         (size_t)RSTRING_LEN(rb_certificate),
                                         xmlSecKeyDataFormatPem) < 0) {
      xmlSecEncCtxDestroy(encCtx);
      xmlFreeNode(encryptedData_node);
      noko_xml_security_error_s_raise("Failed to load certificate");
    }
  }

  // Set key name.
  if (key_name) {
    if (xmlSecKeySetName(encCtx->encKey, (const xmlChar *)key_name) < 0) {
      xmlSecEncCtxDestroy(encCtx);
      xmlFreeNode(encryptedData_node);
      noko_xml_security_error_s_raise("Failed to set key name");
    }
  }

  // encrypt the data
  if (xmlSecEncCtxXmlEncrypt(encCtx, encryptedData_node, node) < 0) {
    xmlSecEncCtxDestroy(encCtx);
    xmlFreeNode(encryptedData_node);
    noko_xml_security_error_s_raise("Encryption failed");
  }

  // the replaced node is orphaned, but not freed; let Nokogiri
  // own it now
  if (encCtx->replacedNodeList != NULL) {
    noko_xml_document_pin_node(encCtx->replacedNodeList);
    // no really, please don't free it
    encCtx->replacedNodeList = NULL;
  }

  xmlSecEncCtxDestroy(encCtx);

  return Qnil;
}

VALUE
noko_xml_node__native_sign(VALUE self,
                           VALUE rb_key,
                           VALUE rb_key_name,
                           VALUE rb_certificate,
                           VALUE rb_canonicalization_algorithm,
                           VALUE rb_digest_algorithm,
                           VALUE rb_signature_algorithm,
                           VALUE rb_uri)
{
  const char *key_name = NULL, *ref_uri = NULL;
  xmlDocPtr doc = NULL;
  xmlNodePtr envelopeNode = NULL;
  xmlNodePtr signNode = NULL;
  xmlNodePtr refNode = NULL;
  xmlNodePtr keyInfo_node = NULL;
  xmlSecDSigCtxPtr dsigCtx = NULL;
  xmlSecTransformId canonicalization_algorithm, signature_algorithm, digest_algorithm;

  xmlsec_reset_last_error();

  Noko_Node_Get_Struct(self, xmlNode, envelopeNode);
  doc = envelopeNode->doc;

  rb_key = xmlsec_obj_as_pem_string(rb_key);
  StringValue(rb_canonicalization_algorithm);
  StringValue(rb_digest_algorithm);
  StringValue(rb_signature_algorithm);

  if (!NIL_P(rb_key_name))  {
    key_name = StringValueCStr(rb_key_name);
  }
  if (!NIL_P(rb_certificate)) {
    rb_certificate = xmlsec_obj_as_pem_string(rb_certificate);
  }
  if (!NIL_P(rb_uri)) {
    ref_uri = StringValueCStr(rb_uri);
  }

  canonicalization_algorithm = xmlsec_get_canonicalization_method(rb_canonicalization_algorithm);
  digest_algorithm = xmlsec_get_digest_method(rb_digest_algorithm);
  signature_algorithm = xmlsec_get_signature_method(rb_signature_algorithm);

  // create signature template for enveloped signature.
  signNode = xmlSecTmplSignatureCreate(doc, canonicalization_algorithm,
                                       signature_algorithm, NULL);
  if (signNode == NULL) {
    noko_xml_security_error_s_raise("Failed to create signature template");
  }

  // add <dsig:Signature/> node to the doc
  xmlAddChild(envelopeNode, signNode);

  refNode = xmlSecTmplSignatureAddReference(signNode, digest_algorithm,
            NULL, (const xmlChar *)ref_uri, NULL);
  if (refNode == NULL) {
    noko_xml_security_error_s_raise("Failed to add reference to signature template");
  }

  // add enveloped transform
  if (xmlSecTmplReferenceAddTransform(refNode, xmlSecTransformEnvelopedId) == NULL) {
    noko_xml_security_error_s_raise("Failed to add enveloped transform to reference");
  }

  if (xmlSecTmplReferenceAddTransform(refNode, canonicalization_algorithm) == NULL) {
    noko_xml_security_error_s_raise("Failed to add canonicalization transform to reference");
  }

  // add <dsig:KeyInfo/>
  keyInfo_node = xmlSecTmplSignatureEnsureKeyInfo(signNode, NULL);
  if (keyInfo_node == NULL) {
    noko_xml_security_error_s_raise("Failed to add KeyInfo to signature template");
  }

  if (!NIL_P(rb_certificate)) {
    // add <dsig:X509Data/>
    if (xmlSecTmplKeyInfoAddX509Data(keyInfo_node) == NULL) {
      noko_xml_security_error_s_raise("Failed to add X509Data to signature template");
    }
  }

  if (key_name) {
    // add <dsig:KeyName/>
    if (xmlSecTmplKeyInfoAddKeyName(keyInfo_node, NULL) == NULL) {
      noko_xml_security_error_s_raise("Failed to add KeyName to signature template");
    }
  }

  dsigCtx = xmlsec_create_dsig_context(NULL);
  if (dsigCtx == NULL) {
    noko_xml_security_error_s_raise("Failed to create signature context");
  }

  // load private key, assuming that there is no password
  dsigCtx->signKey = xmlSecCryptoAppKeyLoadMemory((xmlSecByte *)RSTRING_PTR(rb_key),
                     (size_t)RSTRING_LEN(rb_key),
                     xmlSecKeyDataFormatPem,
                     NULL, // password
                     NULL,
                     NULL);
  if (dsigCtx->signKey == NULL) {
    xmlSecDSigCtxDestroy(dsigCtx);
    noko_xml_security_error_s_raise("Failed to load private key");
  }

  if (key_name) {
    if (xmlSecKeySetName(dsigCtx->signKey, (const xmlChar *)key_name) < 0) {
      xmlSecDSigCtxDestroy(dsigCtx);
      noko_xml_security_error_s_raise("Failed to set key name");
    }
  }

  if (!NIL_P(rb_certificate)) {
    if (xmlSecCryptoAppKeyCertLoadMemory(dsigCtx->signKey,
                                         (xmlSecByte *)RSTRING_PTR(rb_certificate),
                                         (size_t)RSTRING_LEN(rb_certificate),
                                         xmlSecKeyDataFormatPem) < 0) {
      xmlSecDSigCtxDestroy(dsigCtx);
      noko_xml_security_error_s_raise("Failed to load certificate");
    }
  }

  if (xmlSecDSigCtxSign(dsigCtx, signNode) < 0) {
    xmlSecDSigCtxDestroy(dsigCtx);
    noko_xml_security_error_s_raise("Failed to sign the template");
  }

  xmlSecDSigCtxDestroy(dsigCtx);

  return self;
}

VALUE
noko_xml_node__native_verify_signature(VALUE self,
                                       VALUE rb_keys_manager,
                                       VALUE rb_key,
                                       VALUE rb_verification_depth,
                                       VALUE rb_verification_time,
                                       VALUE rb_verify_certificates)
{
  xmlNodePtr node = NULL;
  xmlSecDSigCtxPtr dsigCtx = NULL;
  xmlSecKeysMngrPtr keysMngr = NULL;

  xmlsec_reset_last_error();

  if (!NIL_P(rb_keys_manager)) {
    Noko_XML_Security_Get_Struct(rb_keys_manager, &keysMngr);
  }
  Noko_Node_Get_Struct(self, xmlNode, node);

  if (!xmlSecCheckNodeName(node, xmlSecNodeSignature, xmlSecDSigNs)) {
    rb_raise(rb_eArgError, "Can only verify a Signature node");
  }

  if (!NIL_P(rb_verification_time)) {
    rb_verification_time = rb_Integer(rb_verification_time);
  }

  if (!NIL_P(rb_verification_depth)) {
    rb_verification_depth = rb_Integer(rb_verification_depth);
  }

  if (!NIL_P(rb_key)) {
    rb_key = xmlsec_obj_as_pem_string(rb_key);
  }

  dsigCtx = xmlsec_create_dsig_context(keysMngr);
  if (dsigCtx == NULL) {
    noko_xml_security_error_s_raise("Failed to create signature context");
  }

  if (rb_verify_certificates == Qfalse) {
    dsigCtx->keyInfoReadCtx.flags |= XMLSEC_KEYINFO_FLAGS_X509DATA_DONT_VERIFY_CERTS;
  }

  if (!NIL_P(rb_verification_time)) {
    dsigCtx->keyInfoReadCtx.certsVerificationTime = (time_t)NUM2LONG(rb_verification_time);
  }

  if (!NIL_P(rb_verification_depth)) {
    dsigCtx->keyInfoReadCtx.certsVerificationDepth = NUM2INT(rb_verification_depth);
  }

  if (!NIL_P(rb_key)) {
    // load public key
    dsigCtx->signKey = xmlSecCryptoAppKeyLoadMemory((xmlSecByte *)RSTRING_PTR(rb_key),
                       (size_t)RSTRING_LEN(rb_key),
                       xmlSecKeyDataFormatPem,
                       NULL, // password
                       NULL, NULL);
    if (dsigCtx->signKey == NULL) {
      xmlSecDSigCtxDestroy(dsigCtx);
      noko_xml_security_error_s_raise("Failed to load public key");
    }
  }

  if (xmlSecDSigCtxVerify(dsigCtx, node) < 0) {
    xmlSecDSigCtxDestroy(dsigCtx);
    noko_xml_security_error_s_raise("Error occurred during signature verification");
  }

  if (dsigCtx->status == xmlSecDSigStatusSucceeded) {
    return Qtrue;
  }

  return Qfalse;
}

void
noko_init_xmlsec(void)
{
#ifndef XMLSEC_NO_XSLT
  xsltSecurityPrefsPtr xsltSecPrefs = NULL;
#endif /* XMLSEC_NO_XSLT */

#ifndef XMLSEC_NO_XSLT
  xmlIndentTreeOutput = 1;

  /* Disable all XSLT options that give filesystem and network access. */
  xsltSecPrefs = xsltNewSecurityPrefs();
  xsltSetSecurityPrefs(xsltSecPrefs,  XSLT_SECPREF_READ_FILE,        xsltSecurityForbid);
  xsltSetSecurityPrefs(xsltSecPrefs,  XSLT_SECPREF_WRITE_FILE,       xsltSecurityForbid);
  xsltSetSecurityPrefs(xsltSecPrefs,  XSLT_SECPREF_CREATE_DIRECTORY, xsltSecurityForbid);
  xsltSetSecurityPrefs(xsltSecPrefs,  XSLT_SECPREF_READ_NETWORK,     xsltSecurityForbid);
  xsltSetSecurityPrefs(xsltSecPrefs,  XSLT_SECPREF_WRITE_NETWORK,    xsltSecurityForbid);
  xsltSetDefaultSecurityPrefs(xsltSecPrefs);
#endif /* XMLSEC_NO_XSLT */

// xmlsec overwrites the default external entity loader unless you're running
// xmlsec 1.3.6 or later _and_ libxml2 2.13.0 or later.
// we don't need to do that because all of the defaults in ParseOptions have nonet included
#if LIBXML_VERSION < 21300 || XMLSEC_VERSION_MINOR < 3 || XMLSEC_VERSION_SUBMINOR < 6
  xmlExternalEntityLoader currentExternalEntityLoader = xmlGetExternalEntityLoader();
#endif

  if (xmlSecInit() < 0) {
    rb_raise(rb_eLoadError, "xmlsec initialization failed");
    return;
  }
#if LIBXML_VERSION < 21300 || XMLSEC_VERSION_MINOR < 3 || XMLSEC_VERSION_SUBMINOR < 6
  xmlSetExternalEntityLoader(currentExternalEntityLoader);
#endif
  if (xmlSecCheckVersion() != 1) {
    rb_raise(rb_eLoadError, "xmlsec version is not compatible");
    return;
  }
  // xmlsec doesn't have a convenient way to directly get the loaded version.
  // xmlSecCheckVersion just says "compatible", meaning the loaded version is
  // newer than the compiled version. so do some iterations check "exact" versions
  // to find the loaded version. The common case is we're using the same version
  // we compiled against, so this will break on after the first iterator.
  xmlSecErrorsDefaultCallbackEnableOutput(0);
  int major = XMLSEC_VERSION_MAJOR;
  int minor = XMLSEC_VERSION_MINOR;
  int subminor = XMLSEC_VERSION_SUBMINOR;
  bool found = false;
  while (minor < 100) {
    while (subminor < 100) {
      if (xmlSecCheckVersionExt(major, minor, subminor, xmlSecCheckVersionExactMatch) == 1) {
        found = true;
        break;
      }
      subminor++;
    }
    if (found) {
      break;
    }
    minor++;
    subminor = 0;
  }
  xmlSecErrorsDefaultCallbackEnableOutput(1);
  rb_const_set(mNokogiri, rb_intern("XMLSEC_LOADED_VERSION"), found ? rb_sprintf("%d.%d.%d", major, minor,
               subminor) : NOKOGIRI_STR_NEW("0.0.0", 5));

  // load crypto library if necessary
#ifdef XMLSEC_CRYPTO_DYNAMIC_LOADING
  if (xmlSecCryptoDLLoadLibrary(NULL) < 0) {
    rb_raise(rb_eLoadError,
             "Error: unable to load default xmlsec-crypto library. Make sure"
             "that you have it installed and check shared libraries path\n"
             "(LD_LIBRARY_PATH) environment variable.\n");
    return;
  }
#endif

  if (xmlSecCryptoAppInit(NULL) < 0) {
    rb_raise(rb_eLoadError, "unable to initialize crypto engine");
    return;
  }
  if (xmlSecCryptoInit() < 0) {
    rb_raise(rb_eLoadError, "xmlsec-crypto initialization failed");
  }

  // Set up Ruby methods for XMLSec
  rb_define_private_method(cNokogiriXmlNode, "native_decrypt", noko_xml_node__native_decrypt, 1);
  rb_define_private_method(cNokogiriXmlNode, "native_encrypt", noko_xml_node__native_encrypt, 5);
  rb_define_private_method(cNokogiriXmlNode, "native_sign", noko_xml_node__native_sign, 7);
  rb_define_private_method(cNokogiriXmlNode, "native_verify_signature", noko_xml_node__native_verify_signature, 5);
}
