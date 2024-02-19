#include <nokogiri.h>
#include <xmlsec_util.h>

// Constructs a xmlSecKeysMngrPtr and adds all the certs included in |rb_certs|
// array as trusted certificates.
static xmlSecKeysMngrPtr createKeyManagerWithRbCertArray(
    VALUE rb_certs,
    VALUE* rb_exception_result_out,
    const char** exception_message_out) {
  VALUE rb_exception_result = Qnil;
  const char* exception_message = NULL;

  int i = 0;
  int numCerts = RARRAY_LEN(rb_certs);
  xmlSecKeysMngrPtr keyManager = xmlSecKeysMngrCreate();
  VALUE rb_cert = Qnil;
  char *cert = NULL;
  unsigned int certLength = 0;
  int numSuccessful = 0;

  if (keyManager == NULL) {
    rb_exception_result = cNokogiriXmlsecDecryptionError;
    exception_message = "failed to create keys manager.";
    goto done;
  }

  if (xmlSecCryptoAppDefaultKeysMngrInit(keyManager) < 0) {
    rb_exception_result = cNokogiriXmlsecKeystoreError;
    exception_message = "could not initialize key manager";
    goto done;
  }

  for (i = 0; i < numCerts; i++) {
    rb_cert = RARRAY_PTR(rb_certs)[i];
    rb_cert = rb_obj_as_string(rb_cert);
    Check_Type(rb_cert, T_STRING);
    cert = RSTRING_PTR(rb_cert);
    certLength = RSTRING_LEN(rb_cert);

    if(xmlSecCryptoAppKeysMngrCertLoadMemory(keyManager,
                                             (xmlSecByte *)cert,
                                             certLength,
                                             xmlSecKeyDataFormatPem,
                                             xmlSecKeyDataTypeTrusted) < 0) {
      rb_warn("failed to load certificate at index %d", i);
    } else {
      numSuccessful++;
    }
  }

  // note, numCerts could be zero, meaning that we should use system SSL certs
  if (numSuccessful == 0 && numCerts != 0) {
    rb_exception_result = cNokogiriXmlsecKeystoreError;
    exception_message = "Could not load any of the specified certificates for signature verification";
    goto done;
  }

done:
  if (!NIL_P(rb_exception_result)) {
    if (keyManager) {
      xmlSecKeysMngrDestroy(keyManager);
      keyManager = NULL;
    }
  }

  *rb_exception_result_out = rb_exception_result;
  *exception_message_out = exception_message;
  return keyManager;
}

static int addRubyKeyToManager(VALUE rb_key, VALUE rb_value, VALUE rb_manager) {
  xmlSecKeysMngrPtr keyManager = (xmlSecKeysMngrPtr)rb_manager;
  char *keyName, *keyData;
  unsigned int keyDataLength;
  xmlSecKeyPtr key;

  Check_Type(rb_key, T_STRING);
  Check_Type(rb_value, T_STRING);
  keyName = RSTRING_PTR(rb_key);
  keyData = RSTRING_PTR(rb_value);
  keyDataLength = RSTRING_LEN(rb_value);

  // load key
  key = xmlSecCryptoAppKeyLoadMemory((xmlSecByte *)keyData,
                                     keyDataLength,
                                     xmlSecKeyDataFormatPem,
                                     NULL, // password
                                     NULL, NULL);
  if (key == NULL) {
    rb_warn("failed to load '%s' public or private pem key", keyName);
    return ST_CONTINUE;
  }

  // set key name
  if (xmlSecKeySetName(key, BAD_CAST keyName) < 0) {
    rb_warn("failed to set key name for key '%s'", keyName);
    return ST_CONTINUE;
  }

  // add key to key manager; from now on the manager is responsible for
  // destroying the key
  if (xmlSecCryptoAppDefaultKeysMngrAdoptKey(keyManager, key) < 0) {
    rb_warn("failed to add key '%s' to key manager", keyName);
    return ST_CONTINUE;
  }

  return ST_CONTINUE;
}

// Constructs a xmlSecKeysMngr and adds all the named to key mappings
// specified by the |rb_hash| to the key manager.
//
// Caller takes ownership. Free with xmlSecKeysMngrDestroy().
static xmlSecKeysMngrPtr createKeyManagerFromNamedKeys(
    VALUE rb_hash,
    VALUE* rb_exception_result_out,
    const char** exception_message_out) {
  xmlSecKeysMngrPtr keyManager = xmlSecKeysMngrCreate();
  if (keyManager == NULL) return NULL;
  if (xmlSecCryptoAppDefaultKeysMngrInit(keyManager) < 0) {
    *rb_exception_result_out = cNokogiriXmlsecKeystoreError;
    *exception_message_out = "could not initialize key manager";
    xmlSecKeysMngrDestroy(keyManager);
    return NULL;
  }

  rb_hash_foreach(rb_hash, addRubyKeyToManager, (VALUE)keyManager);

  return keyManager;
}

static VALUE rb_verify_with(VALUE self, VALUE rb_opts) {
  VALUE rb_exception_result = Qnil;
  const char* exception_message = NULL;

  xmlNodePtr node = NULL;
  xmlSecDSigCtxPtr dsigCtx = NULL;
  xmlSecKeysMngrPtr keyManager = NULL;
  VALUE rb_certs, rb_cert;
  VALUE rb_rsa_key;
  VALUE rb_verification_time, rb_verification_depth, rb_verify_certificates;
  char *rsa_key = NULL;
  unsigned int rsa_key_length = 0;
  VALUE result = Qfalse;

  resetXmlSecError();

  Check_Type(rb_opts, T_HASH);
  Noko_Node_Get_Struct(self, xmlNode, node);

  // verify start node
  if(!xmlSecCheckNodeName(node, xmlSecNodeSignature, xmlSecDSigNs)) {
    rb_exception_result = cNokogiriXmlsecVerificationError;
    exception_message = "Can only verify a Signature node";
    goto done;
  }

  rb_certs = rb_hash_aref(rb_opts, ID2SYM(rb_intern("cert")));
  if (NIL_P(rb_certs)) {
    rb_certs = rb_hash_aref(rb_opts, ID2SYM(rb_intern("certs")));
  }

  rb_verification_depth = rb_hash_aref(rb_opts, ID2SYM(rb_intern("verification_depth")));
  rb_verification_time = rb_hash_aref(rb_opts, ID2SYM(rb_intern("verification_time")));
  rb_verify_certificates = rb_hash_aref(rb_opts, ID2SYM(rb_intern("verify_certificates")));

  if (!NIL_P(rb_certs)) {
    if(TYPE(rb_certs) != T_ARRAY) {
      rb_cert = rb_certs;
      rb_certs = rb_ary_new();
      rb_ary_push(rb_certs, rb_cert);
    }

    keyManager = createKeyManagerWithRbCertArray(rb_certs, &rb_exception_result,
                                                 &exception_message);
    if (keyManager == NULL) {
      // Propagate exception.
      goto done;
    }
  } else if (!NIL_P(rb_rsa_key = rb_hash_aref(rb_opts, ID2SYM(rb_intern("key"))))) {
    Check_Type(rb_rsa_key,  T_STRING);
    rsa_key = RSTRING_PTR(rb_rsa_key);
    rsa_key_length = RSTRING_LEN(rb_rsa_key);
  } else {
    keyManager = createKeyManagerFromNamedKeys(rb_opts, &rb_exception_result,
                                               &exception_message);
    if (keyManager == NULL) {
      // Propagate exception.
      goto done;
    }
  }

  // Create signature context.
  dsigCtx = createDSigContext(keyManager);
  if(dsigCtx == NULL) {
    rb_exception_result = cNokogiriXmlsecVerificationError;
    exception_message = "failed to create signature context";
    goto done;
  }

  if(!NIL_P(rb_verification_time)) {
    rb_verification_time = rb_Integer(rb_verification_time);
    dsigCtx->keyInfoReadCtx.certsVerificationTime = (time_t)NUM2LONG(rb_verification_time);
  }

  if(rb_verify_certificates == Qfalse) {
    dsigCtx->keyInfoReadCtx.flags |= XMLSEC_KEYINFO_FLAGS_X509DATA_DONT_VERIFY_CERTS;
  }

  if(!NIL_P(rb_verification_depth)) {
    rb_verification_depth = rb_Integer(rb_verification_depth);
    dsigCtx->keyInfoReadCtx.certsVerificationDepth = (time_t)NUM2LONG(rb_verification_depth);
  }

  if(rsa_key) {
    // load public key
    dsigCtx->signKey = xmlSecCryptoAppKeyLoadMemory((xmlSecByte *)rsa_key,
                                                    rsa_key_length,
                                                    xmlSecKeyDataFormatPem,
                                                    NULL, // password
                                                    NULL, NULL);
    if(dsigCtx->signKey == NULL) {
      rb_exception_result = cNokogiriXmlsecVerificationError;
      exception_message = "failed to load public pem key";
      goto done;
    }
  }

  // verify signature
  if(xmlSecDSigCtxVerify(dsigCtx, node) < 0) {
    rb_exception_result = cNokogiriXmlsecVerificationError;
    exception_message = "error occurred during signature verification";
    goto done;
  }
      
  if(dsigCtx->status == xmlSecDSigStatusSucceeded) {
    result = Qtrue;
  }    

done:
  if(dsigCtx != NULL) {
    xmlSecDSigCtxDestroy(dsigCtx);
  }

  if (keyManager != NULL) {
    xmlSecKeysMngrDestroy(keyManager);
  }

  xmlSecErrorsSetCallback(xmlSecErrorsDefaultCallback);

  if(!NIL_P(rb_exception_result)) {
    if (hasXmlSecLastError()) {
      rb_raise(rb_exception_result, "%s, XmlSec error: %s", exception_message,
               getXmlSecLastError());
    } else {
      rb_raise(rb_exception_result, "%s", exception_message);
    }
  }

  return result;
}

void
noko_xmlsec_init_verify_with(void)
{
  rb_define_method(cNokogiriXmlsecNode, "verify_with", rb_verify_with, 1);
}
