#include <xmlsec_util.h>

#include <xmlsec/errors.h>

xmlSecKeysMngrPtr createKeyManagerWithSingleKey(
    char* keyStr,
    unsigned int keyLength,
    char *keyName,
    VALUE* rb_exception_result_out,
    const char** exception_message_out) {
  VALUE rb_exception_result = Qnil;
  const char* exception_message = NULL;
  xmlSecKeysMngrPtr mngr = NULL;
  xmlSecKeyPtr key = NULL;
  
  /* create and initialize keys manager, we use a simple list based
   * keys manager, implement your own xmlSecKeysStore klass if you need
   * something more sophisticated 
   */
  mngr = xmlSecKeysMngrCreate();
  if(mngr == NULL) {
    rb_exception_result = cNokogiriXmlsecDecryptionError;
    exception_message = "failed to create keys manager.";
    goto done;
  }
  if(xmlSecCryptoAppDefaultKeysMngrInit(mngr) < 0) {
    rb_exception_result = cNokogiriXmlsecDecryptionError;
    exception_message = "failed to initialize keys manager.";
    goto done;
  }    
  
  /* load private RSA key */
  key = xmlSecCryptoAppKeyLoadMemory((xmlSecByte *)keyStr,
                                     keyLength,
                                     xmlSecKeyDataFormatPem,
                                     NULL, // the key file password
                                     NULL, // the key password callback
                                     NULL);// the user context for password callback
  if(key == NULL) {
    rb_exception_result = cNokogiriXmlsecDecryptionError;
    exception_message = "failed to load rsa key";
    goto done;
  }

  if(xmlSecKeySetName(key, BAD_CAST keyName) < 0) {
    rb_exception_result = cNokogiriXmlsecDecryptionError;
    exception_message = "failed to set key name";
    goto done;
  }

  /* add key to keys manager, from now on keys manager is responsible 
   * for destroying key 
   */
  if(xmlSecCryptoAppDefaultKeysMngrAdoptKey(mngr, key) < 0) {
    rb_exception_result = cNokogiriXmlsecDecryptionError;
    exception_message = "failed to add key to keys manager";
    goto done;
  }

done:
  if(rb_exception_result != Qnil) {
    if (key) {
      xmlSecKeyDestroy(key);
    }

    if (mngr) {
      xmlSecKeysMngrDestroy(mngr);
      mngr = NULL;
    }
  }

  *rb_exception_result_out = rb_exception_result;
  *exception_message_out = exception_message;
  return mngr;
}

xmlSecDSigCtxPtr createDSigContext(xmlSecKeysMngrPtr keyManager) {
  xmlSecDSigCtxPtr dsigCtx = xmlSecDSigCtxCreate(keyManager);
  if (!dsigCtx) {
    return NULL;
  }

  // Restrict ReferenceUris to same document or empty to avoid XXE attacks.
  dsigCtx->enabledReferenceUris = xmlSecTransformUriTypeEmpty |
                                  xmlSecTransformUriTypeSameDocument;

  return dsigCtx;
}

#define ERROR_STACK_SIZE      4096
static char g_errorStack[ERROR_STACK_SIZE];
static size_t g_errorStackPos;

char* getXmlSecLastError() {
  return g_errorStack;
}

int hasXmlSecLastError() {
  return g_errorStack[0] != '\0';
}

void resetXmlSecError() {
  g_errorStack[0] = '\0';
  g_errorStackPos = 0;
  xmlSecErrorsSetCallback(storeErrorCallback);
}

void storeErrorCallback(const char *file,
                        int line,
                        const char *func,
                        const char *errorObject,
                        const char *errorSubject,
                        int reason,
                        const char *msg) {
  int i = 0;
  const char* error_msg = NULL;
  int amt = 0;
  if (g_errorStackPos >= ERROR_STACK_SIZE) {
    // Just bail. Earlier errors are more interesting usually anyway.
    return;
  }

  for(i = 0; (i < XMLSEC_ERRORS_MAX_NUMBER) && (xmlSecErrorsGetMsg(i) != NULL); ++i) {
    if(xmlSecErrorsGetCode(i) == reason) {
      error_msg = xmlSecErrorsGetMsg(i);
      break;
    }
  }

  amt = snprintf(
      &g_errorStack[g_errorStackPos],
      ERROR_STACK_SIZE - g_errorStackPos,
      "func=%s:file=%s:line=%d:obj=%s:subj=%s:error=%d:%s:%s\n",
      func, file, line, errorObject, errorSubject, reason,
      error_msg ? error_msg : "", msg);

  if (amt > 0) {
    g_errorStackPos += amt;
  }
}
