#ifndef STRING_SET_H
#define STRING_SET_H

#include <stddef.h>

#if defined(__cplusplus)
extern "C" {
#endif  // __cplusplus

typedef struct hashmap GumboStringSet;

GumboStringSet* gumbo_string_set_new(size_t cap);
void gumbo_string_set_free(GumboStringSet *set);
void gumbo_string_set_insert(GumboStringSet *set, const char *str);
int gumbo_string_set_contains(GumboStringSet *set, const char *str);

#if defined(__cplusplus)
}
#endif  // __cplusplus

#endif  // STRING_SET_H
