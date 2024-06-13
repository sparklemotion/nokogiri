check_LIBRARIES = libgtest_main.a
libgtest_main_a_SOURCES = ../googletest/src/gtest-all.cc ../googletest/src/gtest_main.cc
libgtest_main_a_CPPFLAGS = -I$(top_srcdir)/googletest/include -I$(top_srcdir)/googletest
libgtest_main_a_CXXFLAGS = -pthread

check_PROGRAMS = gumbotest
gumbotest_SOURCES = attribute.cc \
    parser.cc \
    string_buffer.cc \
    string_piece.cc \
    test_utils.cc \
    token_buffer.cc \
    tokenizer.cc \
    utf8.cc \
    vector.cc

gumbotest_LDADD = libgtest_main.a ../src/libgumbo.a
gumbotest_LDFLAGS = -pthread
gumbotest_CPPFLAGS = -I$(top_srcdir)/googletest/include -I$(top_srcdir)/src

TESTS = gumbotest
