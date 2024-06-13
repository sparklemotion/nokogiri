AC_INIT([Gumbo], [1.0])
AC_CONFIG_SRCDIR([src/nokogiri_gumbo.h])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([subdir-objects foreign serial-tests no-dist no-installinfo no-installman -Wall])
AC_PROG_RANLIB
AC_PROG_CC
AC_PROG_CXX
AM_PROG_AR
AM_CONDITIONAL([HAS_TESTS], [test -d "${srcdir}/test"])
AC_CONFIG_FILES([Makefile src/Makefile test/Makefile])
AC_OUTPUT
