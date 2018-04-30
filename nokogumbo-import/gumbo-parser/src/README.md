libgumbo
========

This is an internal fork of the [libgumbo] library, which was copied and
later modified under the terms of the Apache 2.0 [license]. See `lua-gumbo`
commit [`0a04728`] for details of the original import.

Since importing the code, the following notable fixes and improvements
have been made:

* [`8d3b006`]: Fix recording of source positions for `</form>` end tags
* [`1a8d763`]: Replace linear search in `maybe_replace_codepoint()` with a lookup table
* [`6dca79e`]: Replace `strcasecmp()` and `strncasecmp()` with ascii-only equivalents
* [`17ab1d2`]: Fix `TAGSET_INCLUDES` macro to work properly with multiple bit flags
* [`7e56d45`]: Re-implement `gumbo_normalize_svg_tagname()` with a gperf hash
* [`a518d35`]: Replace linear array search in `adjust_svg_attributes()` with a gperf hash
* [`a4a7433`]: Fix duplicate TagSet initializer being ignored in `is_special_node()`
* [`8137fcd`]: Add support for `<dialog>` tag
* [`4b35471`]: Add missing `static` qualifiers to hide symbols that shouldn't be extern
* [`df57c59`], [`03101f3`], [`ea62330`]: Replace use of locale-dependant `ctype.h` functions
  with custom, ASCII-only equivalents


[libgumbo]: https://github.com/google/gumbo-parser/tree/aa91b27b02c0c80c482e24348a457ed7c3c088e0/src
[license]: https://github.com/google/gumbo-parser/blob/aa91b27b02c0c80c482e24348a457ed7c3c088e0/COPYING
[`0a04728`]: https://github.com/craigbarnes/lua-gumbo/commit/0a047282815af86f3367a7d95fefcfe5723ece48
[`8d3b006`]: https://github.com/craigbarnes/lua-gumbo/commit/8d3b006a044106a0006f77791f292585bf5288f4
[`1a8d763`]: https://github.com/craigbarnes/lua-gumbo/commit/1a8d76319116c98f67f0db819caebac8666b93e5
[`6dca79e`]: https://github.com/craigbarnes/lua-gumbo/commit/6dca79e5d7be5d8986fcc982b44a4fd91f533906
[`17ab1d2`]: https://github.com/craigbarnes/lua-gumbo/commit/17ab1d2b4c4742da78c0c8b3329f61a95744c895
[`7e56d45`]: https://github.com/craigbarnes/lua-gumbo/commit/7e56d45c38375c71970e64d6ad0b1bd5a1ffbb63
[`a518d35`]: https://github.com/craigbarnes/lua-gumbo/commit/a518d35d11a1bcf1bb05b7a23384e4b831258fb5
[`a4a7433`]: https://github.com/craigbarnes/lua-gumbo/commit/a4a743309247c7ede6d080245389eef4f50072a3
[`8137fcd`]: https://github.com/craigbarnes/lua-gumbo/commit/8137fcd0e2e251f87fc735b4fb39e22fbcb7b4fe
[`4b35471`]: https://github.com/craigbarnes/lua-gumbo/commit/4b354717f73461dfbd9b2cc21ebe467ebdd9c8da
[`df57c59`]: https://github.com/craigbarnes/lua-gumbo/commit/df57c59b8d46a02eee30803274d932a3e46ff482
[`03101f3`]: https://github.com/craigbarnes/lua-gumbo/commit/03101f3c23f5f6a9ba80741592ca1a2a88579fd1
[`ea62330`]: https://github.com/craigbarnes/lua-gumbo/commit/ea623306cf83fc029dd4d1d2b9aa847abad1b656
