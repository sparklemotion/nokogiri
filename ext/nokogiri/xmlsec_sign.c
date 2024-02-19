#include <nokogiri.h>
#include <xmlsec_options.h>
#include <xmlsec_util.h>

// Appends an xmlsig <dsig:Signature> node to document stored in |self|
// with a signature based on the given key and cert.
//
// Expects a ruby hash for the signing arguments.
// Hash parameters:
//   :key - A PEM encoded rsa key for signing.
//   :cert - The public cert to include with the signature.
//   :signature_alg - Algorithm identified by the URL fragment. Supported algorithms
//             taken from http://www.w3.org/TR/xmldsig-core
//   :digest_alg - Algorithm identified by the URL fragment. Supported algorithms
//             taken from http://www.w3.org/TR/xmldsig-core
//   :name - [optional] String with name of the rsa key.
//   :uri - [optional] The URI attribute for the <Reference> node in the
//          signature.
//   :store_references - [optional] If true, the options hash will be modified,
//             and this value will be replaced with pre-digest buffer for
//             debugging purposes
static VALUE rb_sign(VALUE self, VALUE rb_opts) {
  VALUE rb_exception_result = Qnil;
  const char* exception_message = NULL;

  xmlDocPtr doc = NULL;
  xmlNodePtr envelopeNode = NULL;
  xmlNodePtr signNode = NULL;
  xmlNodePtr refNode = NULL;
  xmlNodePtr keyInfoNode = NULL;
  xmlSecDSigCtxPtr dsigCtx = NULL;
  char *keyName = NULL;
  char *certificate = NULL;
  char *rsaKey = NULL;
  char *refUri = NULL;
  unsigned int rsaKeyLength = 0;
  unsigned int certificateLength = 0;
  VALUE rb_references = Qnil;
  int store_references = 0;
  VALUE rb_pre_digest_buffer_sym, rb_reference, rb_pre_digest_buffer;
  xmlSecSize pos;

  VALUE rb_rsa_key = rb_hash_aref(rb_opts, ID2SYM(rb_intern("key")));
  VALUE rb_cert = rb_hash_aref(rb_opts, ID2SYM(rb_intern("cert")));
  VALUE rb_signature_alg = rb_hash_aref(rb_opts, ID2SYM(rb_intern("signature_alg")));
  VALUE rb_digest_alg = rb_hash_aref(rb_opts, ID2SYM(rb_intern("digest_alg")));
  VALUE rb_uri = rb_hash_aref(rb_opts, ID2SYM(rb_intern("uri")));
  VALUE rb_key_name = rb_hash_aref(rb_opts, ID2SYM(rb_intern("name")));
  VALUE rb_store_references = rb_hash_aref(rb_opts, ID2SYM(rb_intern("store_references")));

  resetXmlSecError();

  Check_Type(rb_rsa_key, T_STRING);
  Check_Type(rb_signature_alg, T_STRING);
  Check_Type(rb_digest_alg, T_STRING);

  rsaKey = RSTRING_PTR(rb_rsa_key);
  rsaKeyLength = RSTRING_LEN(rb_rsa_key);

  if (!NIL_P(rb_cert)) {
    Check_Type(rb_cert, T_STRING);
    certificate = RSTRING_PTR(rb_cert);
    certificateLength = RSTRING_LEN(rb_cert);
  }
  if (!NIL_P(rb_key_name))  {
    Check_Type(rb_key_name, T_STRING);
    keyName = StringValueCStr(rb_key_name);
  }
  if (!NIL_P(rb_uri)) {
    Check_Type(rb_uri, T_STRING);
    refUri = StringValueCStr(rb_uri);
  }
  switch (TYPE(rb_store_references)) {
    case T_TRUE:
      store_references = 1;
      break;
    case T_FALSE:
    case T_NIL:
      break;
    default:
      Check_Type(rb_store_references, T_TRUE);
      break;
  }

  xmlSecTransformId signature_algorithm = GetSignatureMethod(rb_signature_alg,
      &rb_exception_result, &exception_message);
  if (signature_algorithm == xmlSecTransformIdUnknown) {
    // Propagate exception.
    goto done;
  }

  Noko_Node_Get_Struct(self, xmlNode, envelopeNode);
  doc = envelopeNode->doc;
  // create signature template for enveloped signature.
  signNode = xmlSecTmplSignatureCreate(doc, xmlSecTransformExclC14NId,
                                       signature_algorithm, NULL);
  if (signNode == NULL) {
    rb_exception_result = cNokogiriXmlsecSigningError;
    exception_message = "failed to create signature template";
    goto done;
  }

  // add <dsig:Signature/> node to the doc
  xmlAddChild(envelopeNode, signNode);

  // add reference
  xmlSecTransformId digest_algorithm = GetDigestMethod(rb_digest_alg,
      &rb_exception_result, &exception_message);
  if (digest_algorithm == xmlSecTransformIdUnknown) {
    // Propagate exception.
    goto done;
  }
  refNode = xmlSecTmplSignatureAddReference(signNode, digest_algorithm,
                                            NULL, (const xmlChar *)refUri, NULL);
  if(refNode == NULL) {
    rb_exception_result = cNokogiriXmlsecSigningError;
    exception_message = "failed to add reference to signature template";
    goto done;
  }

  // add enveloped transform
  if(xmlSecTmplReferenceAddTransform(refNode, xmlSecTransformEnvelopedId) == NULL) {
    rb_exception_result = cNokogiriXmlsecSigningError;
    exception_message = "failed to add enveloped transform to reference";
    goto done;
  }

  if(xmlSecTmplReferenceAddTransform(refNode, xmlSecTransformExclC14NId) == NULL) {
    rb_exception_result = cNokogiriXmlsecSigningError;
    exception_message = "failed to add canonicalization transform to reference";
    goto done;
  }

  // add <dsig:KeyInfo/>
  keyInfoNode = xmlSecTmplSignatureEnsureKeyInfo(signNode, NULL);
  if(keyInfoNode == NULL) {
    rb_exception_result = cNokogiriXmlsecSigningError;
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

  if(keyName) {
    // add <dsig:KeyName/>
    if(xmlSecTmplKeyInfoAddKeyName(keyInfoNode, NULL) == NULL) {
      rb_exception_result = cNokogiriXmlsecSigningError;
      exception_message = "failed to add key name";
      goto done;
    }
  }

  // create signature context, we don't need keys manager in this example
  dsigCtx = createDSigContext(NULL);
  if(dsigCtx == NULL) {
    rb_exception_result = cNokogiriXmlsecSigningError;
    exception_message = "failed to create signature context";
    goto done;
  }
  if (store_references) {
    dsigCtx->flags |= XMLSEC_DSIG_FLAGS_STORE_SIGNEDINFO_REFERENCES |
      XMLSEC_DSIG_FLAGS_STORE_MANIFEST_REFERENCES;
  }

  // load private key, assuming that there is not password
  dsigCtx->signKey = xmlSecCryptoAppKeyLoadMemory((xmlSecByte *)rsaKey,
                                                  rsaKeyLength,
                                                  xmlSecKeyDataFormatPem,
                                                  NULL, // password
                                                  NULL,
                                                  NULL);
  if(dsigCtx->signKey == NULL) {
    rb_exception_result = cNokogiriXmlsecSigningError;
    exception_message = "failed to load private key";
    goto done;
  }
  
  if(keyName) {
    // set key name
    if(xmlSecKeySetName(dsigCtx->signKey, (xmlSecByte *)keyName) < 0) {
      rb_exception_result = cNokogiriXmlsecSigningError;
      exception_message = "failed to set key name";
      goto done;
    }
  }

  if(certificate) {
    // load certificate and add to the key
    if(xmlSecCryptoAppKeyCertLoadMemory(dsigCtx->signKey,
                                        (xmlSecByte *)certificate,
                                        certificateLength,
                                        xmlSecKeyDataFormatPem) < 0) {
      rb_exception_result = cNokogiriXmlsecSigningError;
      exception_message = "failed to load certificate";
      goto done;
    }
  }

  // sign the template
  if(xmlSecDSigCtxSign(dsigCtx, signNode) < 0) {
    rb_exception_result = cNokogiriXmlsecSigningError;
    exception_message = "signature failed";
    goto done;
  }
  if (store_references) {
    rb_pre_digest_buffer_sym = ID2SYM(rb_intern("pre_digest_buffer"));
    rb_references = rb_ary_new2(xmlSecPtrListGetSize(&dsigCtx->signedInfoReferences));
    rb_hash_aset(rb_opts, ID2SYM(rb_intern("references")), rb_references);

    for(pos = 0; pos < xmlSecPtrListGetSize(&dsigCtx->signedInfoReferences); ++pos) {
      rb_reference = rb_hash_new();
      rb_ary_push(rb_references, rb_reference);
      xmlSecDSigReferenceCtxPtr dsigRefCtx = (xmlSecDSigReferenceCtxPtr)xmlSecPtrListGetItem(&dsigCtx->signedInfoReferences, pos);
      xmlSecBufferPtr pre_digest_buffer = xmlSecDSigReferenceCtxGetPreDigestBuffer(dsigRefCtx);
      if (pre_digest_buffer && xmlSecBufferGetData(pre_digest_buffer)) {
        rb_pre_digest_buffer = rb_str_new((const char *)xmlSecBufferGetData(pre_digest_buffer), xmlSecBufferGetSize(pre_digest_buffer));
        rb_hash_aset(rb_reference, rb_pre_digest_buffer_sym, rb_pre_digest_buffer);
      }
    }
  }

done:
  if(dsigCtx != NULL) {
    xmlSecDSigCtxDestroy(dsigCtx);
  }

  xmlSecErrorsSetCallback(xmlSecErrorsDefaultCallback);

  if(rb_exception_result != Qnil) {
    // remove the signature node before raising an exception, so that
    // the document is untouched
    if (signNode != NULL) {
      xmlUnlinkNode(signNode);
      xmlFreeNode(signNode);
    }

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
noko_xmlsec_init_sign(void)
{
  rb_define_method(cNokogiriXmlsecNode, "sign!", rb_sign, 1);
}