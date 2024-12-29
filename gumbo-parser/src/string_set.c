#include "string_set.h"

#include <string.h>
#include "hashmap.h"

#define SEED0 0xf00ba2
#define SEED1 0xfa1afe1

static int
string_compare(const void *a, const void *b, void *udata) {
  return strcmp((const char *)a, (const char *)b);
}

static uint64_t
string_hash(const void *item, uint64_t seed0, uint64_t seed1) {
  const char *str = (const char *)item;
  return hashmap_xxhash3(str, strlen(str), seed0, seed1);
}

GumboStringSet *
gumbo_string_set_new(size_t cap)
{
  return hashmap_new(sizeof(char *), cap, SEED0, SEED1, string_hash, string_compare, NULL, NULL);
}

void gumbo_string_set_free(GumboStringSet *set)
{
  hashmap_free(set);
}

void
gumbo_string_set_insert(GumboStringSet *set, const char *str)
{
  hashmap_set(set, str);
}

int
gumbo_string_set_contains(GumboStringSet *set, const char *str)
{
  return hashmap_get(set, str) == NULL ? 0 : 1;
}
