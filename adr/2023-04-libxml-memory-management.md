
# 2023-04 Sticking with `ruby_xmalloc` and `ruby_xfree` functions in libxml2

## Status

Affirming the status quo since 2009 -- to use `ruby_xmalloc` et al -- but alternative behavior can be opted into by setting an environment variable:

``` sh
# "default" here means "libxml2's default" which is system malloc
NOKOGIRI_LIBXML_MEMORY_MANAGEMENT=default
```


## Context

### Why Nokogiri originally configured libxml2 with `ruby_xmalloc` and `ruby_xfree`

Since 2009, (0dbe1f82), Nokogiri has configured libxml2 to use `ruby_xmalloc` et al for memory operations by making this call in `Init_nokogiri`:

``` c
  xmlMemSetup(
    (xmlFreeFunc)ruby_xfree,
    (xmlMallocFunc)ruby_xmalloc,
    (xmlReallocFunc)ruby_xrealloc,
    ruby_strdup);
```

The reason for doing this is so that Ruby's garbage collection ("GC") subsystem can track the total heap size, including `malloc` calls by C extensions, and is then able to trigger a GC cycle if the total amount of allocated memory exceeds a limit.

@SamSaffron has a great post that explains how this works, and the antipatterns that can emerge if Ruby is not aware of large amount of allocated memory, and I highly recommend that you read it for context:

> [Ruby's external malloc problem - ruby - Sam Saffron's Blog](https://discuss.samsaffron.com/t/rubys-external-malloc-problem/431)


## Problems

### Problem: Memory edge cases

We've recently run into a few situations where using `ruby_xmalloc` et al was problematic.

- https://github.com/sparklemotion/nokogiri/issues/2059 and https://github.com/sparklemotion/nokogiri/issues/2241 describe situations where libxml2's `atexit` handler called `ruby_xfree` after ObjectSpace was torn down, causing a segfault
- https://github.com/sparklemotion/nokogiri/pull/2807 and https://github.com/sparklemotion/nokogiri/issues/2822 describe a situation where Nokogiri's node lifecycle handling causes libxml2 to merge text nodes (calling `ruby_xmalloc` and `ruby_xfree`) while finalizing a Document, preventing the use of `RUBY_TYPED_FREE_IMMEDIATELY` for Documents
- https://github.com/sparklemotion/nokogiri/issues/2785 describes a situation where libxml2's pthread cleanup code can call `ruby_xfree` after ObjectSpace was torn down, causing a segfault

All the issues have the same root cause: calling `ruby_xfree` in an inappropriate situation, either:

- during GC, or
- after Ruby's object space has been torn down

These situations would not be inappropriate for using system `malloc` and `free`.


### Problem: libxml2 performance

Using `ruby_xmalloc` and `ruby_xfree` has a real performance penalty, as well. Benchmarks at https://github.com/sparklemotion/nokogiri/pull/2843 indicate this penalty can make document parsing up to 34% slower than when the system `malloc` and `free` are used.


## Alternatives considered

### System `malloc`

The primary alternative considered is defaulting to using the system `malloc` and `free`.

However, Sam's blog post (as well as other anecdotal data) makes a great case for being extremely careful about the choice of memory management functions.

Without more data, we're declining to change this behavior. But we are introducing the ability to collect some data by providing a runtime option for selecting the memory management suite.


### Frankenstein `malloc`

Maybe it's possible to build custom memory management functions that perform better but have some of the benefits of the ruby allocator? This feels well beyond the scope of a C extension.

After an inspection of the ruby memory management functions, it wasn't obvious to the author that there's an obvious performance win by eliminating one or the other of a) conditionally invoking GC if `malloc` fails, or b) tracking the number of bytes allocated using `rb_gc_adjust_memory_usage`.

We would welcome experimental results if other people are motivated to try something like this, though.


## Decision

We're sticking with `ruby_xmalloc` et al for now. But we're also introducing an environment variable to allow people to experiment with the system `malloc` if they wish.


## Consequences

No changes to the status quo.


## References

Memory-related issues:

- https://github.com/sparklemotion/nokogiri/issues/2059 (2020)
- https://github.com/sparklemotion/nokogiri/issues/2241 (2021)
- https://github.com/sparklemotion/nokogiri/issues/2785 (2023)
- https://github.com/sparklemotion/nokogiri/pull/2807 (2023)
- https://github.com/sparklemotion/nokogiri/issues/2822 (2023)

Upstream libxml2 exit-time issues, commits, and discussion:

- [Fix memory leak when shared libxml.dll is unloaded (!66)](https://gitlab.gnome.org/GNOME/libxml2/-/merge_requests/66)
- [dlclosing libxml2 with threads crashes (#153)](https://gitlab.gnome.org/GNOME/libxml2/-/issues/153)
- [Call xmlCleanupParser on ELF destruction (!72)](https://gitlab.gnome.org/GNOME/libxml2/-/merge_requests/72)
- [Check for custom free function in global destructor (956534e0)](https://gitlab.gnome.org/GNOME/libxml2/-/commit/956534e02ef280795a187c16f6ac04e107f23c5d)

Performance-related discussion:

- https://github.com/sparklemotion/nokogiri/issues/2722
- https://github.com/sparklemotion/nokogiri/pull/2734
- https://github.com/sparklemotion/nokogiri/pull/2843
