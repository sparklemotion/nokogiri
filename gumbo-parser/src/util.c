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
#include "nokogiri_gumbo.h"

#if GUMBO_USE_ARENA
#include <stdint.h>
#include <assert.h>

static bool is_power_of_two(uintptr_t x) {
	return (x & (x-1)) == 0;
}

static uintptr_t align_forward(uintptr_t ptr, size_t align) {
	uintptr_t p, a, modulo;

	assert(is_power_of_two(align));

	p = ptr;
	a = (uintptr_t)align;
	// Same as (p % a) but faster as 'a' is a power of two
	modulo = p & (a-1);

	if (modulo != 0) {
		// If 'p' address is not aligned, push the address to the
		// next value which is aligned
		p += a - modulo;
	}
	return p;
}

#ifndef DEFAULT_ALIGNMENT
#define DEFAULT_ALIGNMENT (2*sizeof(void *))
#endif

typedef struct Arena Arena;
struct Arena {
	unsigned char *buf;
	size_t         buf_len;
	size_t         prev_offset; // This will be useful for later on
	size_t         curr_offset;
};

static Arena gumbo_arena;

void gumbo_arena_init(size_t backing_buffer_length) {
  void* backing_buffer = malloc(backing_buffer_length);
	gumbo_arena.buf = (unsigned char *)backing_buffer;
	gumbo_arena.buf_len = backing_buffer_length;
	gumbo_arena.curr_offset = 0;
	gumbo_arena.prev_offset = 0;
}

void gumbo_arena_free_all(void) {
  free(gumbo_arena.buf);
	gumbo_arena.buf = 0;
	gumbo_arena.buf_len = 0;
	gumbo_arena.curr_offset = 0;
	gumbo_arena.prev_offset = 0;
}

static void *gumbo_arena_alloc_align(size_t size, size_t align) {
	// Align 'curr_offset' forward to the specified alignment
	uintptr_t curr_ptr = (uintptr_t)gumbo_arena.buf + (uintptr_t)gumbo_arena.curr_offset;
	uintptr_t offset = align_forward(curr_ptr, align);
	offset -= (uintptr_t)gumbo_arena.buf; // Change to relative offset

	// Check to see if the backing memory has space left
	if (offset+size <= gumbo_arena.buf_len) {
		void *ptr = &gumbo_arena.buf[offset];
		gumbo_arena.prev_offset = offset;
		gumbo_arena.curr_offset = offset+size;

		// Zero new memory by default
		memset(ptr, 0, size);
		return ptr;
	}
	// Return NULL if the arena is out of memory (or handle differently)
  assert(0 && "arena out of memory");
	return NULL;
}

// Because C doesn't have default parameters
static void *gumbo_arena_alloc(size_t size) {
	return gumbo_arena_alloc_align(size, DEFAULT_ALIGNMENT);
}

static void gumbo_arena_free(void *ptr) {
	// Do nothing
}

static void *gumbo_arena_resize_align(void *old_memory, size_t old_size, size_t new_size, size_t align) {
	unsigned char *old_mem = (unsigned char *)old_memory;

	assert(is_power_of_two(align));

	if (old_mem == NULL || old_size == 0) {
		return gumbo_arena_alloc_align(new_size, align);
	} else if (gumbo_arena.buf <= old_mem && old_mem < gumbo_arena.buf+gumbo_arena.buf_len) {
		if (gumbo_arena.buf+gumbo_arena.prev_offset == old_mem) {
			gumbo_arena.curr_offset = gumbo_arena.prev_offset + new_size;
			if (new_size > old_size) {
				// Zero the new memory by default
				memset(&gumbo_arena.buf[gumbo_arena.curr_offset], 0, new_size-old_size);
			}
			return old_memory;
		} else {
			void *new_memory = gumbo_arena_alloc_align(new_size, align);
			size_t copy_size = old_size < new_size ? old_size : new_size;
			// Copy across old memory to the new memory
			memmove(new_memory, old_memory, copy_size);
			return new_memory;
		}

	} else {
		assert(0 && "Memory is out of bounds of the buffer in this arena");
		return NULL;
	}

}

// Because C doesn't have default parameters
static void *gumbo_arena_resize(void *old_memory, size_t old_size, size_t new_size) {
	return gumbo_arena_resize_align(old_memory, old_size, new_size, DEFAULT_ALIGNMENT);
}
#else
void gumbo_arena_init(size_t backing_buffer_length) {
}

void gumbo_arena_free_all(void) {
}
#endif /* GUMBO_USE_ARENA */

void* gumbo_alloc(size_t size) {
#if GUMBO_USE_ARENA
  void* ptr = gumbo_arena_alloc(size);
#else
  void* ptr = malloc(size);
#endif
  if (unlikely(ptr == NULL)) {
    perror(__func__);
    abort();
  }
  return ptr;
}

void* gumbo_realloc(void* prev_ptr, size_t prev_size, size_t size) {
#if GUMBO_USE_ARENA
  void* ptr = gumbo_arena_resize(prev_ptr, prev_size, size);
#else
  void* ptr = realloc(prev_ptr, size);
#endif
  if (unlikely(ptr == NULL)) {
    perror(__func__);
    abort();
  }
  return ptr;
}

void gumbo_free(void* ptr) {
#if GUMBO_USE_ARENA
  gumbo_arena_free(ptr);
#else
  free(ptr);
#endif
}

char* gumbo_strdup(const char* str) {
  const size_t size = strlen(str) + 1;
  // The strdup(3) function isn't available in strict "-std=c99" mode
  // (it's part of POSIX, not C99), so use malloc(3) and memcpy(3)
  // instead:
  char* buffer = gumbo_alloc(size);
  return memcpy(buffer, str, size);
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
#endif
