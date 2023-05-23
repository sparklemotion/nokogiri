#include <nokogiri.h>
#include <xmlsec_options.h>
#include <xmlsec_util.h>

static VALUE rb_decrypt_with_key(VALUE self, VALUE rb_key_name, VALUE rb_key) {
  VALUE rb_exception_result = Qnil;
  const char* exception_message = NULL;

  xmlNodePtr node = NULL;
  xmlSecEncCtxPtr encCtx = NULL;
  xmlSecKeysMngrPtr keyManager = NULL;
  char *key = NULL;
  char *keyName = NULL;
  unsigned int keyLength = 0;

  resetXmlSecError();

  Check_Type(rb_key,      T_STRING);
  Check_Type(rb_key_name, T_STRING);
  Noko_Node_Get_Struct(self, xmlNode, node);
  key       = RSTRING_PTR(rb_key);
  keyLength = RSTRING_LEN(rb_key);
  keyName = StringValueCStr(rb_key_name);

  keyManager = createKeyManagerWithSingleKey(key, keyLength, keyName,
                                             &rb_exception_result,
                                             &exception_message);
  if (keyManager == NULL) {
    // Propagate the exception.
    goto done;
  }

  // create encryption context
  encCtx = xmlSecEncCtxCreate(keyManager);
  if(encCtx == NULL) {
    rb_exception_result = cNokogiriXmlsecDecryptionError;
    exception_message = "failed to create encryption context";
    goto done;
  }
  // don't let xmlsec free the node we're looking at out from under us
  encCtx->flags |= XMLSEC_ENC_RETURN_REPLACED_NODE;

  encCtx->keyInfoReadCtx.flags |= XMLSEC_KEYINFO_FLAGS_LAX_KEY_SEARCH;
  encCtx->keyInfoWriteCtx.flags |= XMLSEC_KEYINFO_FLAGS_LAX_KEY_SEARCH;
  
  // decrypt the data
  if((xmlSecEncCtxDecrypt(encCtx, node) < 0) || (encCtx->result == NULL)) {
    rb_exception_result = cNokogiriXmlsecDecryptionError;
    exception_message = "decryption failed";
    goto done;
  }

  if(encCtx->resultReplaced == 0) {
    rb_exception_result = cNokogiriXmlsecDecryptionError;
    exception_message =  "Not implemented: don't know how to handle decrypted, non-XML data yet";
    goto done;
  }

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
noko_xmlsec_init_decrypt_with_key(void)
{
  rb_define_method(cNokogiriXmlsecNode, "decrypt_with_key", rb_decrypt_with_key, 2);  
}
