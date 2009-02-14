#ifndef NOKOGIRI_XML_IO
#define NOKOGIRI_XML_IO

#include <native.h>

int io_read_callback(void * ctx, char * buffer, int len);
int io_write_callback(void * ctx, char * buffer, int len);
int io_close_callback(void * ctx);

#endif
