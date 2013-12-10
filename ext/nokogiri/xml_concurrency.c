#include <xml_concurrency.h>

void * nogvl_mem_parse(struct nogvl_memparse_args * args)
{
  const char * c_buffer = args->string;
  const char * c_url    = args->url;
  const char * c_enc    = args->encoding;
  int len               = args->len;
  int options           = args->options;

  return args->readMemory(c_buffer, len, c_url, c_enc, options);
}
