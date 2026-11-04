// OpenBSD's <sys/cdefs.h> defines `__malloc` as a macro. The gumbo test build
// force-includes this file so that code using `__malloc` as an identifier fails
// to compile on every platform.
#define __malloc __attribute__((__malloc__))
