/*
 Copyright 2017-2018 Craig Barnes.
 Copyright 2010 Google Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "util.h"
#include "gumbo.h"

void* gumbo_alloc(size_t size) {
  void* ptr = malloc(size);
  if (unlikely(ptr == NULL)) {
    perror(__func__);
    abort();
  }
  return ptr;
}

void gumbo_free(void* ptr) {
  free(ptr);
}

char* gumbo_copy_stringz(const char* str) {
  char* buffer = gumbo_alloc(strlen(str) + 1);
  strcpy(buffer, str);
  return buffer;
}

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

#ifdef GUMBO_DEBUG
#include <stdarg.h>
// Debug function to trace operation of the parser
// (define GUMBO_DEBUG to use).
void gumbo_debug(const char* format, ...) {
  va_list args;
  va_start(args, format);
  vprintf(format, args);
  va_end(args);
  fflush(stdout);
}
#else
void gumbo_debug(const char* UNUSED(format), ...) {}
#endif
