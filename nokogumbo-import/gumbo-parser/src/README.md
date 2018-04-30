libgumbo
========

This is an internal fork of the [libgumbo] library, which was copied and
later modified under the terms of the Apache 2.0 [license]. See `lua-gumbo`
commit [`0a047282815a`] for details of the original import.

Since importing the code, the following notable fixes and improvements
have been made:

* `8d3b006`: Fix recording of source positions for `</form>` end tags
* `1a8d763`: Replace linear search in `maybe_replace_codepoint()` with a lookup table
* `6dca79e`: Replace `strcasecmp()` and `strncasecmp()` with ascii-only equivalents
* `17ab1d2`: Fix `TAGSET_INCLUDES` macro to work properly with multiple bit flags
* `7e56d45`: Re-implement `gumbo_normalize_svg_tagname()` with a gperf hash
* `a518d35`: Replace linear array search in `adjust_svg_attributes()` with a gperf hash
* `a4a7433`: Fix duplicate TagSet initializer being ignored in `is_special_node()`
* `8137fcd`: Add support for `<dialog>` tag
* `4b35471`: Add missing `static` qualifiers to hide symbols that shouldn't be extern
* `df57c59`, `03101f3`, `ea62330`: Replace use of locale-dependant `ctype.h` functions
  with custom, ASCII-only equivalents


[libgumbo]: https://github.com/google/gumbo-parser/tree/aa91b27b02c0c80c482e24348a457ed7c3c088e0/src
[license]: https://github.com/google/gumbo-parser/blob/aa91b27b02c0c80c482e24348a457ed7c3c088e0/COPYING
[`0a047282815a`]: https://github.com/craigbarnes/lua-gumbo/commit/0a047282815af86f3367a7d95fefcfe5723ece48
