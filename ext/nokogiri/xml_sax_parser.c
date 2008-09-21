#include <xml_sax_parser.h>

static VALUE parse_memory(VALUE self, VALUE data)
{
  xmlSAXHandlerPtr handler;
  Data_Get_Struct(self, xmlSAXHandler, handler);
  xmlSAXUserParseMemory(  handler,
                          (void *)self,
                          StringValuePtr(data),
                          NUM2INT(rb_funcall(data, rb_intern("length"), 0))
  );
  return data;
}

static void internal_subset(  void * ctx,
                              const xmlChar *name,
                              const xmlChar *external_id,
                              const xmlChar *system_id )
{
  VALUE self = (VALUE)ctx;
  VALUE doc = rb_funcall(self, rb_intern("document"), 0);
  rb_funcall(doc, rb_intern("internal_subset"), 3,
      rb_str_new2((char *)name),
      rb_str_new2((char *)external_id),
      rb_str_new2((char *)system_id));
}

static int is_standalone(void * ctx)
{
  VALUE self = (VALUE)ctx;
  VALUE doc = rb_funcall(self, rb_intern("document"), 0);
  if(Qtrue == rb_funcall(doc, rb_intern("standalone?"), 0))
    return 1;

  return 0;
}

static int has_internal_subset(void * ctx)
{
  VALUE self = (VALUE)ctx;
  VALUE doc = rb_funcall(self, rb_intern("document"), 0);
  if(Qtrue == rb_funcall(doc, rb_intern("internal_subset?"), 0))
    return 1;

  return 0;
}

static int has_external_subset(void * ctx)
{
  VALUE self = (VALUE)ctx;
  VALUE doc = rb_funcall(self, rb_intern("document"), 0);
  if(Qtrue == rb_funcall(doc, rb_intern("external_subset?"), 0))
    return 1;

  return 0;
}

static void start_element(void * ctx, const xmlChar *name, const xmlChar **atts)
{
  VALUE self = (VALUE)ctx;
  VALUE doc = rb_funcall(self, rb_intern("document"), 0);
  VALUE attributes = rb_ary_new();
  xmlChar * attr;
  int i = 0;
  if(atts) {
    while(attr = atts[i]) {
      rb_funcall(attributes, rb_intern("<<"), 1, rb_str_new2((char *)attr));
      i++;
    }
  }

  rb_funcall( doc,
              rb_intern("start_element"),
              2,
              rb_str_new2((char *)name),
              attributes
  );
}

static void deallocate(xmlSAXHandlerPtr handler)
{
  /* FIXME */
  free(handler);
}

static VALUE allocate(VALUE klass)
{
  xmlSAXHandlerPtr handler = calloc(1, sizeof(xmlSAXHandler));

  handler->internalSubset = internal_subset;
  handler->isStandalone = is_standalone;
  handler->hasInternalSubset = has_internal_subset;
  handler->hasExternalSubset = has_external_subset;
  handler->startElement = start_element;

  return Data_Wrap_Struct(klass, NULL, deallocate, handler);
}

VALUE cNokogiriXmlSaxParser ;
void init_xml_sax_parser()
{
  VALUE klass = cNokogiriXmlSaxParser =
    rb_const_get(mNokogiriXmlSax, rb_intern("Parser"));
  rb_define_alloc_func(klass, allocate);
  rb_define_method(klass, "parse_memory", parse_memory, 1);
}
