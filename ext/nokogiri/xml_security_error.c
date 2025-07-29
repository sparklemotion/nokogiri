#include <nokogiri.h>

#include <xmlsec/xmlsec.h>
#include <xmlsec/errors.h>

VALUE cNokogiriXmlSecurityError = Qnil;
VALUE cNokogiriXmlSecurityErrorLocation = Qnil;

typedef struct _xmlsecErrorLocation {
  const char *file;
  int line;
  const char *func;
  const char *error_object;
  const char *error_subject;
  int reason;
  const char *error_message;
  char *msg;
} xmlsecErrorLocation;
typedef xmlsecErrorLocation *xmlsecErrorLocationPtr;

#define ERROR_STACK_SIZE      128
static xmlsecErrorLocation xmlsec_error_stack[ERROR_STACK_SIZE];
static int xmlsec_error_stack_pos = 0;

static
void
store_error_callback(const char *file,
                     int line,
                     const char *func,
                     const char *error_object,
                     const char *error_subject,
                     int reason,
                     const char *msg)
{
  if (xmlsec_error_stack_pos >= ERROR_STACK_SIZE) {
    // Just bail. Earlier errors are more interesting usually anyway.
    return;
  }

  xmlsecErrorLocationPtr error_location = &xmlsec_error_stack[xmlsec_error_stack_pos++];

  error_location->file = file;
  error_location->line = line;
  error_location->func = func;
  error_location->error_object = error_object;
  error_location->error_subject = error_subject;
  error_location->reason = reason;
  error_location->error_message = NULL;
  // if this fails, we're out of memory anyway, and we'll just have to rely on the reason code
  // being useful
  error_location->msg = strdup(msg);
  for (size_t i = 0; (i < XMLSEC_ERRORS_MAX_NUMBER) && (xmlSecErrorsGetMsg(i) != NULL); ++i) {
    if (xmlSecErrorsGetCode(i) == reason) {
      error_location->error_message = xmlSecErrorsGetMsg(i);
      break;
    }
  }
}

void
xmlsec_reset_last_error(void)
{
  while (xmlsec_error_stack_pos > 0) {
    xmlsecErrorLocationPtr error_location = &xmlsec_error_stack[--xmlsec_error_stack_pos];
    if (error_location->msg) {
      free(error_location->msg);
      error_location->msg = NULL;
    }
  }
  xmlSecErrorsSetCallback(store_error_callback);
}

NORETURN_DECL
void
noko_xml_security_error_s_raise(const char *exception_message)
{
  VALUE rb_exception, rb_locations;

  if (xmlsec_error_stack_pos == 0) {
    rb_raise(rb_eRuntimeError, "%s", exception_message);
  }

  rb_locations = rb_ary_new2(xmlsec_error_stack_pos);
  for (int i = 0; i < xmlsec_error_stack_pos; i++) {
    xmlsecErrorLocationPtr error_location = &xmlsec_error_stack[i];

    VALUE rb_error_location = rb_class_new_instance(0, NULL, cNokogiriXmlSecurityErrorLocation);
    rb_iv_set(rb_error_location, "@file", error_location->file ? NOKOGIRI_STR_NEW2(error_location->file) : Qnil);
    rb_iv_set(rb_error_location, "@line", INT2NUM(error_location->line));
    rb_iv_set(rb_error_location, "@func", error_location->func ? NOKOGIRI_STR_NEW2(error_location->func) : Qnil);
    rb_iv_set(rb_error_location, "@error_object",
              error_location->error_object ? NOKOGIRI_STR_NEW2(error_location->error_object) : Qnil);
    rb_iv_set(rb_error_location, "@error_subject",
              error_location->error_subject ? NOKOGIRI_STR_NEW2(error_location->error_subject) : Qnil);
    rb_iv_set(rb_error_location, "@reason", INT2NUM(error_location->reason));
    rb_iv_set(rb_error_location, "@error_message",
              error_location->error_message ? NOKOGIRI_STR_NEW2(error_location->error_message) : Qnil);

    if (error_location->msg) {
      rb_iv_set(rb_error_location, "@msg", NOKOGIRI_STR_NEW2(error_location->msg));
      // msg is allocated in our error callback, so free it as soon as possible
      free(error_location->msg);
      error_location->msg = NULL;
    } else {
      rb_iv_set(rb_error_location, "@msg", Qnil);
    }
    rb_ary_push(rb_locations, rb_error_location);
  }

  rb_exception = rb_class_new_instance(0, NULL, cNokogiriXmlSecurityError);
  rb_iv_set(rb_exception, "@locations", rb_locations);
  rb_exc_raise(rb_exception);
}

void
noko_init_xml_security_error(void)
{
  cNokogiriXmlSecurityErrorLocation = rb_define_class_under(mNokogiriXmlSecurity, "ErrorLocation", rb_cObject);
  cNokogiriXmlSecurityError = rb_define_class_under(mNokogiriXmlSecurity, "Error", rb_eRuntimeError);
}
