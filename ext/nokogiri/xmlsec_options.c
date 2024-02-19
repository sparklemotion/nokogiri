#include <nokogiri.h>
#include <xmlsec_options.h>

#if (XMLSEC_VERSION_MAJOR > 1) || (XMLSEC_VERSION_MAJOR == 1 && (XMLSEC_VERSION_MINOR > 2 || (XMLSEC_VERSION_MINOR == 2 && XMLSEC_VERSION_SUBMINOR >= 20)))
# define HAS_ECDSA 1
#else
# define HAS_ECDSA 0
#endif

// Key Transport Strings.
static const char RSA1_5[] = "rsa-1_5";
static const char RSA_OAEP_MGF1P[] = "rsa-oaep-mgf1p";

// Block Encryption Strings.
static const char TRIPLEDES_CBC[] = "tripledes-cbc";
static const char AES128_CBC[] = "aes128-cbc";
static const char AES256_CBC[] = "aes256-cbc";
static const char AES192_CBC[] = "aes192-cbc";

// Supported signature algorithms taken from #6 of
// http://www.w3.org/TR/xmldsig-core1/
static const char RSA_SHA1[] = "rsa-sha1";
static const char RSA_SHA224[] = "rsa-sha224";
static const char RSA_SHA256[] = "rsa-sha256";
static const char RSA_SHA384[] = "rsa-sha384";
static const char RSA_SHA512[] = "rsa-sha512";
static const char DSA_SHA1[] = "dsa-sha1";

#if HAS_ECDSA
static const char ECDSA_SHA1[] = "ecdsa-sha1";
static const char ECDSA_SHA224[] = "ecdsa-sha224";
static const char ECDSA_SHA256[] = "ecdsa-sha256";
static const char ECDSA_SHA384[] = "ecdsa-sha384";
static const char ECDSA_SHA512[] = "ecdsa-sha512";
static const char DSA_SHA256[] = "dsa-sha256";
#endif  // HAS_ECDSA

// Supported digest algorithms taken from #6 of
// http://www.w3.org/TR/xmldsig-core1/
static const char DIGEST_SHA1[] = "sha1";
static const char DIGEST_SHA224[] = "sha224";
static const char DIGEST_SHA256[] = "sha256";
static const char DIGEST_SHA384[] = "sha384";
static const char DIGEST_SHA512[] = "sha512";

bool GetXmlEncOptions(VALUE rb_opts,
                      XmlEncOptions* options,
                      VALUE* rb_exception_result,
                      const char** exception_message) {
  VALUE rb_block_encryption = rb_hash_aref(rb_opts, ID2SYM(rb_intern("block_encryption")));
  VALUE rb_key_transport = rb_hash_aref(rb_opts, ID2SYM(rb_intern("key_transport")));
  memset(options, 0, sizeof(XmlEncOptions));

  if (NIL_P(rb_block_encryption) ||
      TYPE(rb_block_encryption) != T_STRING ||
      NIL_P(rb_key_transport) ||
      TYPE(rb_key_transport) != T_STRING) {
    *rb_exception_result = rb_eArgError;
    *exception_message = "Must supply :block_encryption & :key_transport";
    return false;
  }

  char* blockEncryptionValue = RSTRING_PTR(rb_block_encryption);
  int blockEncryptionLen = RSTRING_LEN(rb_block_encryption);
  char* keyTransportValue = RSTRING_PTR(rb_key_transport);
  int keyTransportLen = RSTRING_LEN(rb_key_transport);

  if (strncmp(AES256_CBC, blockEncryptionValue, blockEncryptionLen) == 0) {
    options->block_encryption = xmlSecTransformAes256CbcId;
    options->key_type = "aes";
    options->key_bits = 256;
  } else if (strncmp(AES128_CBC, blockEncryptionValue, blockEncryptionLen) == 0) {
    options->block_encryption = xmlSecTransformAes128CbcId;
    options->key_type = "aes";
    options->key_bits = 128;
  } else if (strncmp(AES192_CBC, blockEncryptionValue, blockEncryptionLen) == 0) {
    options->block_encryption = xmlSecTransformAes192CbcId;
    options->key_type = "aes";
    options->key_bits = 192;
  } else if (strncmp(TRIPLEDES_CBC, blockEncryptionValue, blockEncryptionLen) == 0) {
    options->block_encryption = xmlSecTransformDes3CbcId;
    options->key_type = "des";
    options->key_bits = 192;
  } else {
    *rb_exception_result = rb_eArgError;
    *exception_message = "Unknown :block_encryption value";
    return false;
  }

  if (strncmp(RSA1_5, keyTransportValue, keyTransportLen) == 0) {
    options->key_transport = xmlSecTransformRsaPkcs1Id;
  } else if (strncmp(RSA_OAEP_MGF1P, keyTransportValue, keyTransportLen) == 0) {
    options->key_transport = xmlSecTransformRsaOaepId;
  } else {
    *rb_exception_result = rb_eArgError;
    *exception_message = "Unknown :key_transport value";
    return false;
  }

  return true;
}

xmlSecTransformId GetSignatureMethod(VALUE rb_signature_alg,
                                     VALUE* rb_exception_result,
                                     const char** exception_message) {
  const char* signatureAlgorithm = RSTRING_PTR(rb_signature_alg);
  unsigned int signatureAlgorithmLength = RSTRING_LEN(rb_signature_alg);

  if (strncmp(RSA_SHA1, signatureAlgorithm, signatureAlgorithmLength) == 0) {
    return xmlSecTransformRsaSha1Id;
  } else if (strncmp(RSA_SHA224, signatureAlgorithm, signatureAlgorithmLength) == 0) {
    return xmlSecTransformRsaSha224Id;
  } else if (strncmp(RSA_SHA256, signatureAlgorithm, signatureAlgorithmLength) == 0) {
    return xmlSecTransformRsaSha256Id;
  } else if (strncmp(RSA_SHA384, signatureAlgorithm, signatureAlgorithmLength) == 0) {
    return xmlSecTransformRsaSha384Id;
  } else if (strncmp(RSA_SHA512, signatureAlgorithm, signatureAlgorithmLength) == 0) {
    return xmlSecTransformRsaSha512Id;

  }
#if HAS_ECDSA
  else if (strncmp(ECDSA_SHA1, signatureAlgorithm, signatureAlgorithmLength) == 0) {
    return xmlSecTransformEcdsaSha1Id;
  } else if (strncmp(ECDSA_SHA224, signatureAlgorithm, signatureAlgorithmLength) == 0) {
    return xmlSecTransformEcdsaSha224Id;
  } else if (strncmp(ECDSA_SHA256, signatureAlgorithm, signatureAlgorithmLength) == 0) {
    return xmlSecTransformEcdsaSha256Id;
  } else if (strncmp(ECDSA_SHA384, signatureAlgorithm, signatureAlgorithmLength) == 0) {
    return xmlSecTransformEcdsaSha384Id;
  } else if (strncmp(ECDSA_SHA512, signatureAlgorithm, signatureAlgorithmLength) == 0) {
    return xmlSecTransformEcdsaSha512Id;
  } else if (strncmp(DSA_SHA1, signatureAlgorithm, signatureAlgorithmLength) == 0) {
    return xmlSecTransformDsaSha1Id;
  } else if (strncmp(DSA_SHA256, signatureAlgorithm, signatureAlgorithmLength) == 0) {
    return xmlSecTransformDsaSha256Id;
  }
#endif  // HAS_ECDSA

  *rb_exception_result = rb_eArgError;
  *exception_message = "Unknown :signature_alg";
  return xmlSecTransformIdUnknown;
}

xmlSecTransformId GetDigestMethod(VALUE rb_digest_alg,
                                  VALUE* rb_exception_result,
                                  const char** exception_message) {
  const char* digestAlgorithm = RSTRING_PTR(rb_digest_alg);
  unsigned int digestAlgorithmLength = RSTRING_LEN(rb_digest_alg);

  if (strncmp(DIGEST_SHA1, digestAlgorithm, digestAlgorithmLength) == 0) {
    return xmlSecTransformSha1Id;
  } else if (strncmp(DIGEST_SHA224, digestAlgorithm, digestAlgorithmLength) == 0) {
    return xmlSecTransformSha224Id;
  } else if (strncmp(DIGEST_SHA256, digestAlgorithm, digestAlgorithmLength) == 0) {
    return xmlSecTransformSha256Id;
  } else if (strncmp(DIGEST_SHA384, digestAlgorithm, digestAlgorithmLength) == 0) {
    return xmlSecTransformSha384Id;
  } else if (strncmp(DIGEST_SHA512, digestAlgorithm, digestAlgorithmLength) == 0) {
    return xmlSecTransformSha512Id;
  }

  *rb_exception_result = rb_eArgError;
  *exception_message = "Unknown :digest_algorithm";
  return xmlSecTransformIdUnknown;
}
