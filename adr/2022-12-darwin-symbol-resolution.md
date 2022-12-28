
# 2022-12 Hide libxml2 and libxslt symbols on Darwin in Ruby 3.2 native gem

## Status

Accepted, but reversible if an alternative technical solution can be found.


## Context

In the final days of shipping Nokogiri v1.14.0 with native (precompiled) support for Ruby 3.2, we're struggling a bit with symbol resolution.

Ruby 3.2, when compiling on Darwin, uses the `-bundle_loader` linker flag to resolve symbols against the Ruby executable as if it were a shared library. (This means that, when running a Ruby compiled with the `--enable-shared` flag, that the extension will fail to resolve Ruby symbols like `rb_cObject`.)

We can work around that with the `-flat_namespace` linker flag, which mimics the behavior we already see on Linux and allows us to resolve these symbols at runtime. But for reasons I don't fully understand, many Rubies on Darwin seem to load the libxml2 and libxslt dylibs that ship with XCode commandline tools ("CLT"), and so _every_ libxml2 symbol is a collision and resolves to the _wrong_ libxml2 (not the version we've patched and statically linked into the extension).

To work around this last problem, the best solution we know of right now seems to be to avoid exporting those symbols by using the `-load_hidden` flag (or a similar mechanism, there are several we could choose from).


## Decision

Nokogiri v1.14.0's precompiled native gem for Darwin (MacOS) Ruby 3.2 will be built with:

- the `-flat_namespace` flag to ensure the extension can be used by both `--enable-shared` and `--disable-shared` Rubies,
- and the `-load_hidden` flag for both `libxml2` and `libxslt` to avoid accidentally resolving to non-vendored versions of those libraries


## Consequences

This would prevent accidental symbol collisions such as the https://github.com/sparklemotion/nokogiri/pull/2106 on Linux, and would ensure that we always pull in the desired version of libxml2, avoiding problems like the ones we're currently experiencing with Ruby 3.2 (see https://github.com/rake-compiler/rake-compiler-dock/issues/87 for extended discussion and more links).

This would also, however, prevent a small but non-zero number of downstream gems from integrating with Nokogiri's C API, or the C API of libxml2, libxslt, or libgumbo. A notable gem that did this was https://github.com/rubys/nokogumbo (now merged into Nokogiri itself). Another notable gem that I know that does this is `nokogiri-xmlsec` (and the various forks of it, the most popular seems to be https://github.com/instructure/nokogiri-xmlsec-instructure). So this may prevent experimentation and innovation (see Nokogumbo) as well as putting hurdles in front of useful integrations like xmlsec.


## Alternatives considered

__Remove the `-bundle_loader` flag from the link line.__ Although this works, it feels a bit like fighting the toolchain and the Ruby core team. It's a bit more complicated of a solution, it's harder for me to reason about, and I'm not positive we won't discover some weird side effect later on.

__Fully hide all symbols everywhere__ is taking the chosen solution to the extreme, and may be what we decide to do in the future (see [RFC: Stop exporting symbols · Discussion #2746 · sparklemotion/nokogiri](https://github.com/sparklemotion/nokogiri/discussions/2746)). For now, though, I'd like to keep our options open and not break compatibility completely in this v1.14.0 release. By only doing this where we're forced to, we have a chance to learn about how the API is being used, and also buy some time to hear feedback and to find an alternative solution.

__Stop precompiling__ or __Stop vendoring libraries__ should always be options we consider, because offering native gems and vendoring libraries introduces complexity. However, I covered many of the reasons I think it's good for Nokogiri to do this in [my RubyConf 2021 talk titled "Building Native Extensions. This Could Take A While..."](https://www.youtube.com/watch?v=jtpOci5o50g) and those reasons are still valid, notably our ability to patch libxml2 for performance (see [#2144](https://github.com/sparklemotion/nokogiri/pull/2144)), functional (see [#2403](https://github.com/sparklemotion/nokogiri/pull/2403)), or security (see [#2294](https://github.com/sparklemotion/nokogiri/pull/2294)) reasons.


## References

- Ruby commit introducing `-bundle_loader`: https://github.com/ruby/ruby/commit/50d81bf
- The PR implementing this decision is [dep: add ruby 3.2 support by flavorjones · Pull Request #2732 · sparklemotion/nokogiri](https://github.com/sparklemotion/nokogiri/pull/2732)
- Future symbol visibility decision will be made at [RFC: Stop exporting symbols · Discussion #2746 · sparklemotion/nokogiri](https://github.com/sparklemotion/nokogiri/discussions/2746)
- Background context and solution details at
  - [[Ruby 3.2] having runtime issues on darwin · Issue #87 · rake-compiler/rake-compiler-dock](https://github.com/rake-compiler/rake-compiler-dock/issues/87)
  - https://github.com/stevecheckoway/bundle_test
  - [explore whether \`-load\_hidden\` will work around flat namespace by flavorjones · Pull Request #1 · stevecheckoway/bundle\_test](https://github.com/stevecheckoway/bundle_test/pull/1)
- [Video from Apple explaining the Darwin toolchain changes](https://developer.apple.com/videos/play/wwdc2022/110362/)
