#ifndef NOKOGIRI_XML_CONCURRENCY
#define NOKOGIRI_XML_CONCURRENCY

#include <nokogiri.h>

struct nogvl_memparse_args {
  const char * string;
  const char * url;
  const char * encoding;
  int len;
  int options;
  void * (*readMemory)(const char *, int, const char *, const char *, int);
};

void * nogvl_mem_parse(struct nogvl_memparse_args * args);

#endif
