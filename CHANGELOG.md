# Nokogiri Changelog

Nokogiri follows [Semantic Versioning](https://semver.org/), please see the [README.md](README.md) for details.

---

## next / unreleased

### Improved

* [CRuby] The HTML5 parser now has linear performance when parsing many attributes. Previously performance was quadratic due to two hotspots, one in detecting duplicate attributes and one in constructing the libxml2 data structures. (#3393) @flavorjones


### Dependencies

* [CRuby] Update to rake-compiler-dock v1.9.1 for building precompiled native gems. (#3404, #3418) @flavorjones


## v1.18.1 / 2024-12-29

### Fixed

* [CRuby] XML::SAX::ParserContext keeps a reference to the input to avoid a potential use-after-free issue that's existed since v1.4.0 (2009). (#3395) @flavorjones


## v1.18.0 / 2024-12-25

### Notable Changes

#### Ruby

This release introduces native gem support for Ruby 3.4.

This release ends support for Ruby 3.0, for which [upstream support ended 2024-04-23](https://www.ruby-lang.org/en/downloads/branches/).

This release ships separate precompiled GNU and Musl gems for all linux platforms. Previously both GNU and Musl target systems could use and install the same gem, e.g., the platform gem for `x86_64-linux`. Now, however, the precompiled gem platforms would be `x86_64-linux-gnu` and `x86_64-linux-musl`. So long as you're on `bundler >= 2.5.6` this should be seamless other than perhaps needing to update the platforms in your "Gemfile.lock".

This release drops precompiled native platform gems for `x86-linux` and `x86-mingw32`. **These platforms are still supported.** Users on these platforms must install the "ruby platform" gem which requires a compiler toolchain. See [Installing the `ruby` platform gem](https://nokogiri.org/tutorials/installing_nokogiri.html#installing-the-ruby-platform-gem) in the installation docs. (#3369, #3081)


### Improved

* [CRuby] CSS and XPath queries are faster now that `Node#xpath`, `Node#css`, and related functions are using a faster XPathContext initialization process. We benchmarked a 1.9x improvement for a 6kb file. Big thanks to @nwellnhof for helping with this one. (#3378, superseded by #3389) @flavorjones


### Dependencies

* [CRuby] Update to rake-compiler-dock v1.7.0 for building precompiled native gems. (#3375, #3392) @flavorjones


## v1.17.2 / 2024-12-12

### Fixed

* [JRuby] Fixed an issue where `Node#dup` when called with the `new_parent_doc` parameter was not decorating the node with the document's `Node` decorators. [#3372] @flavorjones


## v1.17.1 / 2024-12-10

### Fixed

* Fixed a potential segfault when using `Node#dup` and `DocumentFragment#dup`. [#3359] @byroot @flavorjones
* `Node#dup` and `Node#clone` now correctly decorate the new node with the document's `Node` decorators. [#3363] @flavorjones


## v1.17.0 / 2024-12-08

### Dependencies

* [CRuby] Vendored libxml2 is updated to [v2.13.5](https://gitlab.gnome.org/GNOME/libxml2/-/releases/v2.13.5). @flavorjones
* [CRuby] Vendored libxslt is updated to [v1.1.42](https://gitlab.gnome.org/GNOME/libxslt/-/releases/v1.1.42). @flavorjones
* [CRuby] Minimum supported version of libxml2 raised to v2.9.2 (released 2014-10-16) from v2.6.21. [#3232, #3287] @flavorjones
* [JRuby] Minimum supported version of Java raised to 8 (released 2014-03-18) from 7. [#3134] @flavorjones
* [CRuby] Update to rake-compiler-dock v1.5.1 for building precompiled native gems. [#3216] @flavorjones


### Notable changes

#### SAX Parsers

The XML and HTML4 SAX parsers have received a lot of attention in this release, and we've fixed multiple long-standing bugs with encoding and entity handling. In addition, libxml2 v2.13 has also made some underlying fixes and improvements to encoding and entity handling.

We're shipping these fixes in a minor release because we firmly believe the resulting behavior is correct and standards-compliant, however applications that have been depending on the buggy behavior may be impacted.

If your application relies on the SAX parsers, and in particular if you're SAX-parsing documents with parsed entities or incorrect encoding declarations, please read the changelog below carefully.


#### Fragment parsing

Document fragment parsing has been improved, particularly with respect to handling malformed fragments or fragments with implicit namespace prefixes. Namespace reconciliation still isn't where we want it to be, but it's an improvement.

HTML5 fragment parsing now allows the context node to be specified as a `context:` keyword argument to the `HTML5::DocumentFragment.parse` and `.new` methods, which should allow for more flexible sanitization and future support for the [draft HTML Sanitizer API](https://wicg.github.io/sanitizer-api/) in downstream libraries.


#### Error handling

In scenarios where multiple errors could be reported by the underlying parser, the errors will be aggregated into a single `Nokogiri::XML::SyntaxError` that is raised. Previously only the final error reported by libxml2 was raised (which was often misleading if it was only a warning and not the fatal error).


#### Schema validation

We've resolved many long-standing bugs in the various schema classes, validation methods, and their error reporting. Behavior is now consistent across schema types and input types, as well as parser backends (Xerces and libxml2).


#### Keyword arguments

The following methods now accept keyword arguments in addition to positional arguments, and use `...` parameter forwarding when possible:
`HTML4()`, `HTML4.fragment`, `HTML4.parse`, `HTML4::Document.parse`, `HTML4::DocumentFragment#initialize`, `HTML4::DocumentFragment.parse`, `HTML5()`, `HTML5.fragment`, `HTML5.parse`, `HTML5::Document.parse`, `HTML5::Document.read_io`, `HTML5::Document.read_memory`, `HTML5::DocumentFragment#initialize`, `HTML5::DocumentFragment.parse`, `XML()`, `XML.fragment`, `XML.parse`, `XML::Document.parse`, `XML::DocumentFragment#initialize`, `XML::DocumentFragment.parse`, `XML::Node#canonicalize`, `XML::Node.parse`, `XML::Reader()`, `XML::RelaxNG()`, `XML::RelaxNG.new`, `XML::RelaxNG.read_memory`, `XML::SAX::PushParser#initialize`, `XML::Schema()`, `XML::Schema.new`, `XML::Schema.read_memory`, and `XSLT()`.

Special thanks to those contributors who participated in the RubyConf 2024 Hack Day to work on #3323 to help modernize Nokogiri by adding keyword arguments and using parameter forwarding in many methods, and expanding some of the documentation! We intend to continue adding keyword argument support to more methods. #3323 #3324 #3326 #3327 #3329 #3330 #3332 #3333 #3334 #3335 #3336 #3342 #3355 #3356 @infews @matiasow @MattJones @mononoken @openbl @flavorjones


### Added

* Introduce support for a new SAX callback `XML::SAX::Document#reference`, which is called to report some parsed XML entities when `XML::SAX::ParserContext#replace_entities` is set to the default value `false`. This is necessary functionality for some applications that were previously relying on incorrect entity error reporting which has been fixed (see below). For more information, read the docs for `Nokogiri::XML::SAX::Document`. [#1926] @flavorjones
* `XML::SAX::Parser#parse_memory` and `#parse_file` now accept an optional `encoding` argument. When not provided, the parser will fall back to the encoding passed to the initializer, and then fall back to autodetection. [#3288] @flavorjones
* `XML::SAX::ParserContext.memory` now accepts an optional `encoding` argument. When not provided, the encoding will be autodetected. [#3288] @flavorjones
* New readonly attributes `XML::DocumentFragment#parse_options` and `HTML4::DocumentFragment#parse_options` return the options used to parse the document fragment. @flavorjones
* New method `XML::Reader.new` is the primary constructor to which `XML::Reader()` forwards. Both methods now take `url:`, `encoding:`, and `options:` kwargs in addition to  the previous calling convention of passing positional parameters. #3326 @infews @flavorjones
* [CRuby] The HTML5 parse methods accept a `:parse_noscript_content_as_text` keyword argument which will emulate the parsing behavior of a browser which has scripting enabled. [#3178, #3231] @stevecheckoway
* [CRuby] `HTML5::DocumentFragment.parse` and `.new` accept a `:context` keyword argument that is the parse context node or element name. Previously this could only be passed in as a positional argument to `.new` and not at all to `.parse`. @flavorjones
* [CRuby] `Nokogiri::HTML5::Builder` is similar to `HTML4::Builder` but returns an `HTML5::Document`. [#3119] @flavorjones
* [CRuby] Attributes in an HTML5 document can be serialized individually, something that has always been supported by the HTML4 serializer. [#3125, #3127] @flavorjones
* [CRuby] Introduce a compile-time option, `--disable-xml2-legacy`, to remove from libxml2 its dependencies on `zlib` and `liblzma` and disable implicit `HTTP` network requests. These all remain enabled by default, and are present in the precompiled native gems. This option is a precursor for removing these libraries in a future major release, but may be interesting for the security-minded who do not need features like automatic decompression and would like to remove these dependencies. You can read more and give feedback on these plans in #3168. [#3247] @flavorjones
* [CRuby] If errors are returned from schema validation, a new attribute `SyntaxError#path` will contain the XPath path of the node that caused the validation failure. [#3316] @ryanong


### Improved

* Documentation has been improved for `XML::RelaxNG`, `XML::Schema`, `XML::Reader`, `HTML5`, `HTML5::Document`, `HTML5::DocumentFragment`, `HTML4::Document`, `HTML4::DocumentFragment`, `XML`, `XML::Document`, `XML::DocumentFragment`. #3355 @flavorjones
* Documentation has been improved for `CSS.xpath_for`. [#3224] @flavorjones
* Documentation for the SAX parsing classes has been greatly improved, including encoding overrides and the complex entity-handling behavior. [#3265] @flavorjones
* `XML::Schema#read_memory` and `XML::RelaxNG#read_memory` are now Ruby methods that call `#from_document`. Previously these were native functions, but they were buggy on both CRuby and JRuby (but worse on JRuby) and so this is now useful, comparable in performance, and simpler code that is easier to maintain. [#2113, #2115] @flavorjones
* `XML::SAX::ParserContext.io`'s `encoding` argument is now optional, and can now be an `Encoding` or an encoding name. When not provided will default to autodetecting the encoding. [#3288] @flavorjones
* [CRuby] The update to libxml v2.13 improves "in context" fragment parsing recovery. We removed our hacky workaround for recovery that led to silently-degraded functionality when parsing fragments with parse errors. Specifically, malformed XML fragments that used implicit namespace prefixes will now "link up" to the namespaces in the parent document or node, where previously they did not. [#2092] @flavorjones
* [CRuby] When multiple errors could be detected by the parser and there's no obvious document to save them in (for example, when parsing a document with the recovery parse option turned off), the libxml2 errors are aggregated into a single `Nokogiri::XML::SyntaxError`. Previously, only the last error recorded by libxml2 was raised, which might be misleading if it's merely a warning and not the fatal error preventing the operation. [#2562] @flavorjones
* [CRuby] The SAX parser context and handler implementation has been simplified and now takes advantage of some of libxml2's default SAX handlers for entities and DTD management. [#3265] @flavorjones
* [CRuby] When compiling packaged libraries from source, allow users' `AR` and `LD` environment variables to set the archiver and linker commands, respectively. This augments the existing `CC` environment variable to set the compiler command. [#3165] @ziggythehamster
* [CRuby] When building from source on MacOS, environment variables `AR` and `RANLIB` are now respected when set instead of being overridden to /usr/bin/{ar,ranlib} (which is still the default). [#3338] @joshheinrichs-shopify


### Fixed

* `Node#clone`, `NodeSet#clone`, and `*::Document#clone` all properly copy the metaclass of the original as expected. Previously, `#clone` had been aliased to `#dup` for these classes (since v1.3.0 in 2009). [#316, #3117] @flavorjones
* CSS queries for pseudo-selectors that cannot be translated into XPath expressions now raise a more descriptive `Nokogiri::CSS::SyntaxError` when they are parsed. Previously, an invalid XPath expression was evaluated and a hard-to-understand XPath error was raised by the query engine. [#3193] @flavorjones
* `Schema#validate` returns errors on empty and malformed files. Previously, it would return errors on empty/malformed Documents, but not when reading from files. [#642] @flavorjones
* `XML::Builder` is now consistent with how it sets block scope. Previously, missing methods with blocks on dynamically-created nodes were always handled by invoking `instance_eval(&block)` on the Builder, even when the Builder was yielding self for all other missing methods with blocks. [#1041] @flavorjones
* `HTML4::DocumentFragment.parse` accepts `IO` input. Previously, it required a string and would raise a `TypeError` when passed an `IO`. [#2069] @sharvy
* [CRuby] libgumbo (the HTML5 parser) treats reaching max-depth as EOF. This addresses a class of issues when the parser is interrupted in this way. [#3121] @stevecheckoway
* [CRuby] Update node GC lifecycle to avoid a potential memory leak with fragments in libxml 2.13.0 caused by changes in `xmlAddChild`. [#3156] @flavorjones
* [CRuby] libgumbo correctly prints nonstandard element names in error messages. [#3219] @stevecheckoway
* [CRuby] External entity references no long cause the SAX parser to register errors. [#1926] @flavorjones
* [JRuby] Fixed entity reference serialization, which rendered both the reference and the replacement text. Incredibly nobody noticed this bug for over a decade. [#3272] @flavorjones
* [JRuby] Fixed some bugs in how `Node#attributes` handles attributes with namespaces. [#2677, #2679] @flavorjones
* [JRuby] Fix `Schema#validate` to only return the most recent Document's errors. Previously, if multiple documents were validated, this method returned the accumulated errors of all previous documents. [#1282] @flavorjones
* [JRuby] Fix `Schema#validate` to not clobber the `@errors` instance variable. [#1282] @flavorjones
* [JRuby] Empty documents fail schema validation as they should. [#783] @flavorjones
* [JRuby] SAX parsing now respects the `#replace_entities` attribute, which defaults to `false`. Previously this flag defaulted to `true` and was completely ignored. [#614] @flavorjones
* [JRuby] The SAX callback `Document#start_element_namespace` received a blank string for the URI when a namespace was not present. It now receives `nil` (as does the CRuby impl). [#3265] @flavorjones
* [JRuby] `Reader#outer_xml` and `#inner_xml` encode entities properly. [#1523] @flavorjones


### Changed

* [CRuby] `Nokogiri::XML::CData.new` no longer accepts `nil` as the content argument, making `CData` behave like other character data classes (like `Comment` and `Text`). This change was necessitated by behavioral changes in libxml2 v2.13.0. If you wish to create an empty CDATA node, pass an empty string. [#3156] @flavorjones
* Internals:
    * The internal `CSS::XPathVisitor` class now accepts the xpath prefix and the context namespaces as constructor arguments. The `prefix:` and `ns:` keyword arguments to `CSS.xpath_for` cannot be specified if the `visitor:` keyword argument is also used. `CSS::XPathVisitor` now exposes `#builtins`, `#doctype`, `#prefix`, and `#namespaces` attributes. [#3225] @flavorjones
    * The internal CSS selector cache has been extracted into a distinct class, `CSS::SelectorCache`. Previously it was part of the `CSS::Parser` class. [#3226] @flavorjones
    * The internal `Gumbo.parse` and `Gumbo.fragment` methods now take keyword arguments instead of positional arguments. [#3199] @flavorjones


### Deprecated

* The undocumented and unused method `Nokogiri::CSS.parse` is now deprecated and will generate a warning. The AST returned by this method is private and subject to change and removal in future versions of Nokogiri. This method will be removed in a future version of Nokogiri.
* Passing an options hash to `CSS.xpath_for` is now deprecated and will generate a warning. Use keyword arguments instead. This will become an error in a future version of Nokogiri.
* Passing libxml2 encoding IDs to `SAX::ParserContext` methods is now deprecated and will generate a warning. The use of `SAX::Parser::ENCODINGS` is also deprecated. Use `Encoding` objects or encoding names instead.


### Thank you!

The following people and organizations were kind enough to sponsor @flavorjones or the Nokogiri project during the development of v1.17.0:

* via Github sponsors
    * renuo @renuo
    * Ajaya Agrawalla @ajaya
    * Rob Stringer @Mycobee
    * Better Stack Community @betterstack-community
    * Prowly @prowlycom
    * Maxime Gauthier @biximilien
    * Harry Lascelles @hlascelles
    * Evil Martians @evilmartians
    * Typesense @typesense
    * YOSHIDA Katsuhiko @kyoshidajp
    * Quan Nguyen @qu8n
    * Sentry @getsentry
    * Codecov @codecov
    * Frank Groeneveld @frenkel
    * Hiroshi SHIBATA @hsbt
    * Nando Vieira @fnando
    * Orien Madgwick @orien
    * Avo @avo-hq
    * Zoran Pesic @zokioki
    * @zzak
    * Graham Watts @GingerGraham
    * Nandang Permana Kusuma @nandangpk
    * Mr. Henry @mrhenry
    * Götz Görisch @GoetzGoerisch
    * Andrew Nesbitt @andrew
* via Thanks.dev
    * Sentry @getsentry
    * Codecov @codecov
    * Keygen @keygen-sh
    * Keith Bauson @kwbauson
    * Nicco Kunzmann @niccokunzmann
    * timhaynes @timhaynes
* via Open Collective
    * Airbnb @airbnb
    * Nemo @captn3m0
    * Velocity Labs @velocity-labs

We'd also like to thank @github who donate a ton of compute time for our CI pipelines!


## v1.16.8 / 2024-12-02

### Fixed

* [CRuby] When serializing HTML5 documents, properly escape foreign content "style" elements. Normally, a "style" tag contains  raw text that does not need entity-escaping, but when it appears in either SVG or MathML foreign content, the "style" tag is now correctly escaped when serialized. @flavorjones


## v1.16.7 / 2024-07-27

## Dependencies

* [CRuby] Vendored libxml2 is updated to [v2.12.9](https://gitlab.gnome.org/GNOME/libxml2/-/releases/v2.12.9), which the upstream release notes state is a security release to address CVE-2024-40896. Nokogiri's maintainers believe this vulnerability does not affect users of Nokogiri, but we advise upgrading at your earliest convenience anyway.


## v1.16.6 / 2024-06-13

## Dependencies

* [CRuby] Vendored libxml2 is updated to [v2.12.8](https://gitlab.gnome.org/GNOME/libxml2/-/releases/v2.12.8), which the release notes state is a bugfix release.


## v1.16.5

### Security

* [CRuby] Vendored libxml2 is updated to address CVE-2024-34459. See [GHSA-r95h-9x8f-r3f7](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-r95h-9x8f-r3f7) for more information.


### Dependencies

* [CRuby] Vendored libxml2 is updated to [v2.12.7](https://gitlab.gnome.org/GNOME/libxml2/-/releases/v2.12.7) from v2.12.6. (@flavorjones)


## v1.16.4 / 2024-04-10

### Dependencies

* [CRuby] Vendored zlib in the precompiled native gems is updated to [v1.3.1](https://zlib.net/ChangeLog.txt) from v1.3. Nokogiri is not affected by the minizip CVE patched in this version, but this update may satisfy some security scanners. Related, see [this discussion](https://github.com/sparklemotion/nokogiri/discussions/3168) about removing the compression libraries altogether in a future version of Nokogiri.


## v1.16.3 / 2024-03-15

### Dependencies

* [CRuby] Vendored libxml2 is updated to [v2.12.6](https://gitlab.gnome.org/GNOME/libxml2/-/releases/v2.12.6) from v2.12.5. (@flavorjones)


### Changed

* [CRuby] `XML::Reader` sets the `@encoding` instance variable during reading if it is not passed into the initializer. Previously, it would remain `nil`. The behavior of `Reader#encoding` has not changed. This works around changes to how libxml2 reports the encoding used in v2.12.6.


## v1.16.2 / 2024-02-04

### Security

* [CRuby] Vendored libxml2 is updated to address CVE-2024-25062. See [GHSA-xc9x-jj77-9p9j](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-xc9x-jj77-9p9j) for more information.


### Dependencies

* [CRuby] Vendored libxml2 is updated to [v2.12.5](https://gitlab.gnome.org/GNOME/libxml2/-/releases/v2.12.5) from v2.12.4. (@flavorjones)


## v1.16.1 / 2024-02-03

### Dependencies

* [CRuby] Vendored libxml2 is updated to [v2.12.4](https://gitlab.gnome.org/GNOME/libxml2/-/releases/v2.12.4) from v2.12.3. (@flavorjones)


### Fixed

* [CRuby] `XML::Reader` defaults the encoding to UTF-8 if it's not specified in either the document or as a method parameter. Previously non-ASCII characters were serialized as NCRs in this case. [#2891] (@flavorjones)
* [CRuby] Restored support for compilation by GCC versions earlier than 4.6, which was broken in v1.15.0 (540e9aee). [#3090] (@adfoster-r7)
* [CRuby] Patched upstream libxml2 to allow parsing HTML5 in the context of a namespaced node (e.g., foreign content like MathML). [#3112, #3116] (@flavorjones)
* [CRuby] Fixed a small memory leak in libgumbo (HTML5 parser) when the maximum tree depth limit is hit. [#3098, #3100] (@stevecheckoway)


## v1.16.0 / 2023-12-27

### Notable Changes

#### Ruby

This release introduces native gem support for Ruby 3.3.

This release ends support for Ruby 2.7, for which [upstream support ended 2023-03-31](https://www.ruby-lang.org/en/downloads/branches/).


#### Pattern matching

This version marks _official support_ for the pattern matching API in `XML::Attr`, `XML::Document`, `XML::DocumentFragment`, `XML::Namespace`, `XML::Node`, and `XML::NodeSet` (and their subclasses), originally introduced as an experimental feature in v1.14.0. (@flavorjones)

Documentation on what can be matched:

* [`XML::Attr#deconstruct_keys`](https://nokogiri.org/rdoc/Nokogiri/XML/Attr.html?h=deconstruct#method-i-deconstruct_keys)
* [`XML::Document#deconstruct_keys`](https://nokogiri.org/rdoc/Nokogiri/XML/Document.html?h=deconstruct#method-i-deconstruct_keys)
* [`XML::Namespace#deconstruct_keys`](https://nokogiri.org/rdoc/Nokogiri/XML/Namespace.html?h=deconstruct+namespace#method-i-deconstruct_keys)
* [`XML::Node#deconstruct_keys`](https://nokogiri.org/rdoc/Nokogiri/XML/Node.html?h=deconstruct#method-i-deconstruct_keys)
* [`XML::DocumentFragment#deconstruct`](https://nokogiri.org/rdoc/Nokogiri/XML/DocumentFragment.html?h=deconstruct#method-i-deconstruct)
* [`XML::NodeSet#deconstruct`](https://nokogiri.org/rdoc/Nokogiri/XML/NodeSet.html?h=deconstruct#method-i-deconstruct)


### Dependencies

* [CRuby] Vendored libxml2 is updated to v2.12.3 from v2.11.6. (@flavorjones)
    * https://gitlab.gnome.org/GNOME/libxml2/-/releases/v2.12.0
    * https://gitlab.gnome.org/GNOME/libxml2/-/releases/v2.12.1
    * https://gitlab.gnome.org/GNOME/libxml2/-/releases/v2.12.2
    * https://gitlab.gnome.org/GNOME/libxml2/-/releases/v2.12.3


### Fixed

* CSS `nth` pseudo-classes now handle spaces, e.g. `"2n + 1"`. [#3018] (@fusion2004)
* [CRuby] `libgumbo` no longer leaks memory when an incomplete tag is abandoned by the HTML5 parser. [#3036] (@flavorjones)


### Removed

* Removed `Nokogiri::HTML5.get` which was deprecated in v1.12.0. [#2278] (@flavorjones)
* Removed the CSS-to-XPath utility modules `XPathVisitorAlwaysUseBuiltins` and `XPathVisitorOptimallyUseBuiltins`, which were deprecated in v1.13.0 in favor of `XPathVisitor` constructor args. [#2403] (@flavorjones)
* Removed `XML::Reader#attribute_nodes` which was deprecated in v1.13.8 in favor of `#attribute_hash`. [#2598, #2599] (@flavorjones)
* [CRuby] Removed the `libxml/libxml2_path` key from `VersionInfo`, used in the past for third-party library integration, in favor of the `nokogiri/cppflags` and `nokogiri/ldflags` keys. Please note that third-party library integration is not fully supported and may be deprecated soon, see #2746 for more context. [#2143] (@flavorjones)


### Thank you!

The following people and organizations were kind enough to sponsor @flavorjones or the Nokogiri project during the development of v1.16.0:

* Götz Görisch @GoetzGoerisch
* Airbnb @airbnb
* Maxime Gauthier @biximilien
* Renuo AG @renuo
* YOSHIDA Katsuhiko @kyoshidajp
* Homebrew @Homebrew
* Hiroshi SHIBATA @hsbt
* @zzak
* Evil Martians @evilmartians
* Ajaya Agrawalla @ajaya
* Modern Treasury @Modern-Treasury
* Danilo Lessa Bernardineli @danlessa
* matt marques @mestre-dos-magos
* Quan Nguyen @qu8n
* Harry Lascelles @hlascelles
* Oleksandr Tyshchenko @altivi
* Prowly @prowlycom
* Better Stack Community @betterstack-community
* Sentry @getsentry
* Codecov @codecov
* Typesense @typesense
* Roy Boivin II @Yabbo
* Frank Groeneveld @frenkel

We'd also like to thank @github who donate a ton of compute time for our CI pipelines!

## Older releases

See [misc/CHANGELOG-archive.md](misc/CHANGELOG-archive.md)
