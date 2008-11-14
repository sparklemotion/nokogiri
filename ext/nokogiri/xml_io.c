#include <xml_io.h>

int io_read_callback(void * ctx, char * buffer, int len) {
  VALUE io = (VALUE)ctx;
  VALUE string = rb_funcall(io, rb_intern("read"), 1, INT2NUM(len));

  if(Qnil == string) return 0;
  VALUE length = rb_funcall(string, rb_intern("length"), 0);

  memcpy(buffer, StringValuePtr(string), (unsigned int)NUM2INT(length));

  return NUM2INT(length);
}

int io_close_callback(void * ctx) {
  return 0;
}
