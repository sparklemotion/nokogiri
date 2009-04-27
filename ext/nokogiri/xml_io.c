#include <xml_io.h>

int io_read_callback(void * ctx, char * buffer, int len) {
  VALUE io = (VALUE)ctx;
  VALUE string = rb_funcall(io, rb_intern("read"), 1, INT2NUM(len));

  if(Qnil == string) return 0;

  memcpy(buffer, StringValuePtr(string), (unsigned int)RSTRING_LEN(string));

  return RSTRING_LEN(string);
}

int io_write_callback(void * ctx, char * buffer, int len) {
  VALUE io = (VALUE)ctx;
  VALUE string = rb_str_new(buffer, len);

  rb_funcall(io, rb_intern("write"), 1, string);
  return len;
}

int io_close_callback(void * ctx) {
  return 0;
}
