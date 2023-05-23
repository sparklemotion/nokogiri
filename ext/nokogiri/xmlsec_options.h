#ifndef NOKOGIRI_EXT_XMLSEC_OPTIONS_H
#define NOKOGIRI_EXT_XMLSEC_OPTIONS_H

#include <ruby.h>
#include <xmlsec/crypto.h>
#include <xmlsec/transforms.h>

typedef struct {
  // From :block_encryption
  xmlSecTransformId block_encryption;
  const char* key_type;
  int key_bits;

  // From :key_transport
  xmlSecTransformId key_transport;
} XmlEncOptions;

// Supported algorithms taken from #5.1 of
// http://www.w3.org/TR/xmlenc-core
//
// For options, only use the URL fragment (stuff post #)
// since that's unique enough and it removes a lot of typing.
bool GetXmlEncOptions(VALUE rb_opts, XmlEncOptions* options,
                      VALUE* rb_exception_result,
                      const char** exception_message);

// XML DSIG helpers.
xmlSecTransformId GetSignatureMethod(VALUE rb_method,
                                     VALUE* rb_exception_result,
                                     const char** exception_message);
xmlSecTransformId GetDigestMethod(VALUE rb_digest_method,
                                  VALUE* rb_exception_result,
                                  const char** exception_message);

#endif  // NOKOGIRI_EXT_XMLSEC_OPTIONS_H
