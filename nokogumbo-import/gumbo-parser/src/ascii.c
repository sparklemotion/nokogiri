#include "ascii.h"

int gumbo_ascii_strcasecmp(const char *s1, const char *s2) {
  int c1, c2;
  while (*s1 && *s2) {
    c1 = (int)(unsigned char) gumbo_ascii_tolower(*s1);
    c2 = (int)(unsigned char) gumbo_ascii_tolower(*s2);
    if (c1 != c2) {
      return (c1 - c2);
    }
    s1++; s2++;
  }
  return (((int)(unsigned char) *s1) - ((int)(unsigned char) *s2));
}

int gumbo_ascii_strncasecmp(const char *s1, const char *s2, size_t n) {
  int c1, c2;
  while (n && *s1 && *s2) {
    n -= 1;
    c1 = (int)(unsigned char) gumbo_ascii_tolower(*s1);
    c2 = (int)(unsigned char) gumbo_ascii_tolower(*s2);
    if (c1 != c2) {
      return (c1 - c2);
    }
    s1++; s2++;
  }
  if (n) {
    return (((int)(unsigned char) *s1) - ((int)(unsigned char) *s2));
  }
  return 0;
}
