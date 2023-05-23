#ifndef NOKOGIRI_EXT_XMLSEC_UTIL_H
#define NOKOGIRI_EXT_XMLSEC_UTIL_H

#include <nokogiri.h>

// Constructs a xmlSecKeysMngr and adds the given named key to the manager.
//
// Caller takes ownership. Free with xmlSecKeysMngrDestroy().
xmlSecKeysMngrPtr createKeyManagerWithSingleKey(
    char* keyStr,
    unsigned int keyLength,
    char *keyName,
    VALUE* rb_exception_result_out,
    const char** exception_message_out);

// Creates a xmlSecDSigCtx with defaults locked down to prevent XXE.
//
// Caller takes ownership of the context. Free with xmlSecDSigCtxDestroy().
xmlSecDSigCtxPtr createDSigContext(xmlSecKeysMngrPtr keyManager);

// Retrieves the recorded error strings from libxmlsec1. Ensure resetXmlSecError()
// is called at the start of the range of error collection.
char* getXmlSecLastError();

// Reset the recording of errors. After this getXmlSecLastError() will return
// an empty string. Call at the start of a logical interaction with libxmlsec.
void resetXmlSecError();

// Return false if there are no errors. If false, getXmlSecLastError() will
// return an empty string.
int hasXmlSecLastError();

// Error reporting hooks to redirect Xmlsec1 library errors away from stdout.
void storeErrorCallback(const char *file,
                        int line,
                        const char *func,
                        const char *errorObject,
                        const char *errorSubject,
                        int reason,
                        const char *msg);

#endif  // NOKOGIRI_EXT_XMLSEC_UTIL_H
