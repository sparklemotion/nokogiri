# Nokogiri Changelog

Nokogiri follows [Semantic Versioning](https://semver.org/), please see the [README.md](README.md) for details.

---

## 1.14.0 / unreleased

### Notes

#### Faster, more reliable installation: Native Gem for ARM64 Linux

This version of Nokogiri ships full native gem support for the `aarch64-linux` platform, which should support AWS Graviton and other ARM Linux platforms. Please note that glibc >= 2.29 is required for aarch64-linux systems, see [Supported Platforms](https://nokogiri.org/#supported-platforms) for more information.


#### Maven-managed JRuby dependencies

This version of Nokogiri uses [`jar-dependencies`](https://github.com/mkristian/jar-dependencies) to manage most of the vendored Java dependencies. `nokogiri -v` now outputs maven metadata for all Java dependencies, and `Nokogiri::VERSION_INFO` also contains this metadata. [[#2432](https://github.com/sparklemotion/nokogiri/issues/2432)]


### Dependencies

* [JRuby] Vendored Jing is updated from com.thaiopensource:jing:20091111 to nu.validator:jing:20200702VNU.
* [JRuby] New dependency on Saxon-HE 9.6.0-4 (via nu.validator:jing:20200702VNU).


### Fixed

* [CRuby] UTF-16-encoded documents longer than ~4000 code points now serialize properly. Previously the serialized document was corrupted when it exceeded the length of libxml2's internal string buffer. [[#752](https://github.com/sparklemotion/nokogiri/issues/752)]
* [HTML5] The Gumbo parser now correctly handles text at the end of `form` elements.
* `{HTML4,XML}::SAX::{Parser,ParserContext}` constructor methods now raise `TypeError` instead of segfaulting when an incorrect type is passed. (Thanks to [@agustingianni](https://github.com/agustingianni) from the Github Security Lab for reporting!)


### Improved

* Compare `Encoding` objects rather than compare their names. This is a slight performance improvement and is future-proof. [[#2454](https://github.com/sparklemotion/nokogiri/issues/2454)] (Thanks, [@casperisfine](https://github.com/casperisfine)!)
* Avoid compile-time conflict with system-installed `gumbo.h` on OpenBSD. [[#2464](https://github.com/sparklemotion/nokogiri/issues/2464)]
* Remove calls to `vasprintf` in favor of platform-independent `rb_vsprintf`
* Prefer `ruby_xmalloc` to `malloc` within the C extension. [[#2480](https://github.com/sparklemotion/nokogiri/issues/2480)] (Thanks, [@Garfield96](https://github.com/Garfield96)!)
* Installation from source on systems missing libiconv will once again generate a helpful error message (broken since v1.11.0). [[#2505](https://github.com/sparklemotion/nokogiri/issues/2505)]


## 1.13.5 / 2022-05-04

### Security

* [CRuby] Vendored libxml2 is updated to address [CVE-2022-29824](https://nvd.nist.gov/vuln/detail/CVE-2022-29824). See [GHSA-cgx6-hpwq-fhv5](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-cgx6-hpwq-fhv5) for more information.


### Dependencies

* [CRuby] Vendored libxml2 is updated from v2.9.13 to [v2.9.14](https://gitlab.gnome.org/GNOME/libxml2/-/releases/v2.9.14).


### Improvements

* [CRuby] The libxml2 HTML parser no longer exhibits quadratic behavior when recovering some broken markup related to start-of-tag and bare `<` characters.


### Changed

* [CRuby] The libxml2 HTML parser in v2.9.14 recovers from some broken markup differently. Notably, the XML CDATA escape sequence `<![CDATA[` and incorrectly-opened comments will result in HTML text nodes starting with `&lt;!` instead of skipping the invalid tag. This behavior is a direct result of the [quadratic-behavior fix](https://gitlab.gnome.org/GNOME/libxml2/-/commit/798bdf1) noted above. The behavior of downstream sanitizers relying on this behavior will also change. Some tests describing the changed behavior are in [`test/html4/test_comments.rb`](https://github.com/sparklemotion/nokogiri/blob/3ed5bf2b5a367cb9dc6e329c5a1c512e1dd4565d/test/html4/test_comments.rb#L187-L204).


## 1.13.4 / 2022-04-11

### Security

* Address [CVE-2022-24836](https://nvd.nist.gov/vuln/detail/CVE-2022-24836), a regular expression denial-of-service vulnerability. See [GHSA-crjr-9rc5-ghw8](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-crjr-9rc5-ghw8) for more information.
* [CRuby] Vendored zlib is updated to address [CVE-2018-25032](https://nvd.nist.gov/vuln/detail/CVE-2018-25032). See [GHSA-v6gp-9mmm-c6p5](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-v6gp-9mmm-c6p5) for more information.
* [JRuby] Vendored Xerces-J (`xerces:xercesImpl`) is updated to address [CVE-2022-23437](https://nvd.nist.gov/vuln/detail/CVE-2022-23437). See [GHSA-xxx9-3xcr-gjj3](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-xxx9-3xcr-gjj3) for more information.
* [JRuby] Vendored nekohtml (`org.cyberneko.html`) is updated to address [CVE-2022-24839](https://nvd.nist.gov/vuln/detail/CVE-2022-24839). See [GHSA-gx8x-g87m-h5q6](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-gx8x-g87m-h5q6) for more information.


### Dependencies

* [CRuby] Vendored zlib is updated from 1.2.11 to 1.2.12. (See [LICENSE-DEPENDENCIES.md](https://github.com/sparklemotion/nokogiri/blob/v1.13.x/LICENSE-DEPENDENCIES.md#platform-releases) for details on which packages redistribute this library.)
* [JRuby] Vendored Xerces-J (`xerces:xercesImpl`) is updated from 2.12.0 to 2.12.2.
* [JRuby] Vendored nekohtml (`org.cyberneko.html`) is updated from a fork of 1.9.21 to 1.9.22.noko2. This fork is now publicly developed at https://github.com/sparklemotion/nekohtml


## 1.13.3 / 2022-02-21

### Fixed

* [CRuby] Revert a HTML4 parser bug in libxml 2.9.13 (introduced in Nokogiri v1.13.2). The bug causes libxml2's HTML4 parser to fail to recover when encountering a bare `<` character in some contexts. This version of Nokogiri restores the earlier behavior, which is to recover from the parse error and treat the `<` as normal character data (which will be serialized as `&lt;` in a text node). The bug (and the fix) is only relevant when the `RECOVER` parse option is set, as it is by default. [[#2461](https://github.com/sparklemotion/nokogiri/issues/2461)]


## 1.13.2 / 2022-02-21

### Security

* [CRuby] Vendored libxml2 is updated from 2.9.12 to 2.9.13. This update addresses [CVE-2022-23308](https://nvd.nist.gov/vuln/detail/CVE-2022-23308).
* [CRuby] Vendored libxslt is updated from 1.1.34 to 1.1.35. This update addresses [CVE-2021-30560](https://nvd.nist.gov/vuln/detail/CVE-2021-30560).

Please see [GHSA-fq42-c5rg-92c2](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-fq42-c5rg-92c2) for more information about these CVEs.


### Dependencies

* [CRuby] Vendored libxml2 is updated from 2.9.12 to 2.9.13. Full changelog is available at https://download.gnome.org/sources/libxml2/2.9/libxml2-2.9.13.news
* [CRuby] Vendored libxslt is updated from 1.1.34 to 1.1.35. Full changelog is available at https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.35.news


## 1.13.1 / 2022-01-13

### Fixed

* Fix `Nokogiri::XSLT.quote_params` regression in v1.13.0 that raised an exception when non-string stylesheet parameters were passed. Non-string parameters (e.g., integers and symbols) are now explicitly supported and both keys and values will be stringified with `#to_s`. [[#2418](https://github.com/sparklemotion/nokogiri/issues/2418)]
* Fix CSS selector query regression in v1.13.0 that raised an `Nokogiri::XML::XPath::SyntaxError` when parsing XPath attributes mixed into the CSS query. Although this mash-up of XPath and CSS syntax previously worked unintentionally, it is now an officially supported feature and is documented as such. [[#2419](https://github.com/sparklemotion/nokogiri/issues/2419)]


## 1.13.0 / 2022-01-06

### Notes

#### Ruby

This release introduces native gem support for Ruby 3.1. Please note that Windows users should use the `x64-mingw-ucrt` platform gem for Ruby 3.1, and `x64-mingw32` for Ruby 2.6&ndash;3.0 (see [RubyInstaller 3.1.0 release notes](https://rubyinstaller.org/2021/12/31/rubyinstaller-3.1.0-1-released.html)).

This release ends support for:

* Ruby 2.5, for which [official support ended 2021-03-31](https://www.ruby-lang.org/en/downloads/branches/).
* JRuby 9.2, which is a Ruby 2.5-compatible release.


#### Faster, more reliable installation: Native Gem for ARM64 Linux

This version of Nokogiri ships experimental native gem support for the `aarch64-linux` platform, which should support AWS Graviton and other ARM Linux platforms. We don't yet have CI running for this platform, and so we're interested in hearing back from y'all whether this is working, and what problems you're seeing. Please send us feedback here: [Feedback: Have you used the `aarch64-linux` native gem?](https://github.com/sparklemotion/nokogiri/discussions/2359)


#### Publishing

This version of Nokogiri opts-in to the ["MFA required to publish" setting](https://guides.rubygems.org/mfa-requirement-opt-in/) on Rubygems.org. This and all future Nokogiri gem files must be published to Rubygems by an account with multi-factor authentication enabled. This should provide some additional protection against supply-chain attacks.

A related discussion about Trust exists at [#2357](https://github.com/sparklemotion/nokogiri/issues/2357) in which I invite you to participate if you have feelings or opinions on this topic.


### Dependencies

* [CRuby] Vendored libiconv is updated from 1.15 to 1.16. (Note that libiconv is only redistributed in the native windows and native darwin gems, see [`LICENSE-DEPENDENCIES.md`](LICENSE-DEPENDENCIES.md) for more information.) [[#2206](https://github.com/sparklemotion/nokogiri/issues/2206)]
* [CRuby] Upgrade mini_portile2 dependency from `~> 2.6.1` to `~> 2.7.0`. ("ruby" platform gem only.)


### Improved

* `{XML,HTML4}::DocumentFragment` constructors all now take an optional parse options parameter or block (similar to Document constructors). [[#1692](https://github.com/sparklemotion/nokogiri/issues/1692)] (Thanks, [@JackMc](https://github.com/JackMc)!)
* `Nokogiri::CSS.xpath_for` allows an `XPathVisitor` to be injected, for finer-grained control over how CSS queries are translated into XPath.
* [CRuby] `XML::Reader#encoding` will return the encoding detected by the parser when it's not passed to the constructor. [[#980](https://github.com/sparklemotion/nokogiri/issues/980)]
* [CRuby] Handle abruptly-closed HTML comments as recommended by WHATWG. (Thanks to [tehryanx](https://hackerone.com/tehryanx?type=user) for reporting!)
* [CRuby] `Node#line` is no longer capped at 65535. libxml v2.9.0 and later support a new parse option, exposed as `Nokogiri::XML::ParseOptions::PARSE_BIG_LINES`, which is turned on by default in `ParseOptions::DEFAULT_{XML,XSLT,HTML,SCHEMA}` (Note that JRuby already supported large line numbers.) [[#1764](https://github.com/sparklemotion/nokogiri/issues/1764), [#1493](https://github.com/sparklemotion/nokogiri/issues/1493), [#1617](https://github.com/sparklemotion/nokogiri/issues/1617), [#1505](https://github.com/sparklemotion/nokogiri/issues/1505), [#1003](https://github.com/sparklemotion/nokogiri/issues/1003), [#533](https://github.com/sparklemotion/nokogiri/issues/533)]
* [CRuby] If a cycle is introduced when reparenting a node (i.e., the node becomes its own ancestor), a `RuntimeError` is raised. libxml2 does no checking for this, which means cycles would otherwise result in infinite loops on subsequent operations. (Note that JRuby already did this.) [[#1912](https://github.com/sparklemotion/nokogiri/issues/1912)]
* [CRuby] Source builds will download zlib and libiconv via HTTPS. ("ruby" platform gem only.) [[#2391](https://github.com/sparklemotion/nokogiri/issues/2391)] (Thanks, [@jmartin-r7](https://github.com/jmartin-r7)!)
* [JRuby] `Node#line` behavior has been modified to return the line number of the node in the _final DOM structure_. This behavior is different from CRuby, which returns the node's position in the _input string_. Ideally the two implementations would be the same, but at least is now officially documented and tested. The real-world impact of this change is that the value returned in JRuby is greater by 1 to account for the XML prolog in the output. [[#2380](https://github.com/sparklemotion/nokogiri/issues/2380)] (Thanks, [@dabdine](https://github.com/dabdine)!)


### Fixed

* CSS queries on HTML5 documents now correctly match foreign elements (SVG, MathML) when namespaces are not specified in the query. [[#2376](https://github.com/sparklemotion/nokogiri/issues/2376)]
* `XML::Builder` blocks restore context properly when exceptions are raised. [[#2372](https://github.com/sparklemotion/nokogiri/issues/2372)] (Thanks, [@ric2b](https://github.com/ric2b) and [@rinthedev](https://github.com/rinthedev)!)
* The `Nokogiri::CSS::Parser` cache now uses the `XPathVisitor` configuration as part of the cache key, preventing incorrect cache results from being returned when multiple `XPathVisitor` options are being used.
* Error recovery from in-context parsing (e.g., `Node#parse`) now always uses the correct `DocumentFragment` class. Previously `Nokogiri::HTML4::DocumentFragment` was always used, even for XML documents. [[#1158](https://github.com/sparklemotion/nokogiri/issues/1158)]
* `DocumentFragment#>` now works properly, matching a CSS selector against only the fragment roots. [[#1857](https://github.com/sparklemotion/nokogiri/issues/1857)]
* `XML::DocumentFragment#errors` now correctly contains any parsing errors encountered. Previously this was always empty. (Note that `HTML::DocumentFragment#errors` already did this.)
* [CRuby] Fix memory leak in `Document#canonicalize` when inclusive namespaces are passed in. [[#2345](https://github.com/sparklemotion/nokogiri/issues/2345)]
* [CRuby] Fix memory leak in `Document#canonicalize` when an argument type error is raised. [[#2345](https://github.com/sparklemotion/nokogiri/issues/2345)]
* [CRuby] Fix memory leak in `EncodingHandler` where iconv handlers were not being cleaned up. [[#2345](https://github.com/sparklemotion/nokogiri/issues/2345)]
* [CRuby] Fix memory leak in XPath custom handlers where string arguments were not being cleaned up. [[#2345](https://github.com/sparklemotion/nokogiri/issues/2345)]
* [CRuby] Fix memory leak in `Reader#base_uri` where the string returned by libxml2 was not freed. [[#2347](https://github.com/sparklemotion/nokogiri/issues/2347)]
* [JRuby] Deleting a `Namespace` from a `NodeSet` no longer modifies the `href` to be the default namespace URL.
* [JRuby] Fix XHTML formatting of closing tags for non-container elements. [[#2355](https://github.com/sparklemotion/nokogiri/issues/2355)]


### Deprecated

* Passing a `Nokogiri::XML::Node` as the second parameter to `Node.new` is deprecated and will generate a warning. This parameter should be a kind of `Nokogiri::XML::Document`. This will become an error in a future version of Nokogiri. [[#975](https://github.com/sparklemotion/nokogiri/issues/975)]
* `Nokogiri::CSS::Parser`, `Nokogiri::CSS::Tokenizer`, and `Nokogiri::CSS::Node` are now internal-only APIs that are no longer documented, and should not be considered stable. With the introduction of `XPathVisitor` injection into `Nokogiri::CSS.xpath_for` there should be no reason to rely on these internal APIs.
* CSS-to-XPath utility classes `Nokogiri::CSS::XPathVisitorAlwaysUseBuiltins` and `XPathVisitorOptimallyUseBuiltins` are deprecated. Prefer `Nokogiri::CSS::XPathVisitor` with appropriate constructor arguments. These classes will be removed in a future version of Nokogiri.


## 1.12.5 / 2021-09-27

### Security

[JRuby] Address CVE-2021-41098 ([GHSA-2rr5-8q37-2w7h](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-2rr5-8q37-2w7h)).

In Nokogiri v1.12.4 and earlier, on JRuby only, the SAX parsers resolve external entities (XXE) by default. This fix turns off entity-resolution-by-default in the JRuby SAX parsers to match the CRuby SAX parsers' behavior.

CRuby users are not affected by this CVE.


### Fixed

* [CRuby] `Document#to_xhtml` properly serializes self-closing tags in libxml > 2.9.10. A behavior change introduced in libxml 2.9.11 resulted in emitting start and and tags (e.g., `<br></br>`) instead of a self-closing tag (e.g., `<br/>`) in previous Nokogiri versions. [[#2324](https://github.com/sparklemotion/nokogiri/issues/2324)]


## 1.12.4 / 2021-08-29

### Notable fix: Namespace inheritance

Namespace behavior when reparenting nodes has historically been poorly specified and the behavior diverged between CRuby and JRuby. As a result, making this behavior consistent in v1.12.0 introduced a breaking change.

This patch release reverts the Builder behavior present in v1.12.0..v1.12.3 but keeps the Document behavior. This release also introduces a Document attribute to allow affected users to easily change this behavior for their legacy code without invasive changes.


#### Compensating Feature in XML::Document

This release of Nokogiri introduces a new `Document` boolean attribute, `namespace_inheritance`, which controls whether children should inherit a namespace when they are reparented. `Nokogiri::XML:Document` defaults this attribute to `false` meaning "do not inherit," thereby making explicit the behavior change introduced in v1.12.0.

CRuby users who desire the pre-v1.12.0 behavior may set `document.namespace_inheritance = true` before reparenting nodes.

See https://nokogiri.org/rdoc/Nokogiri/XML/Document.html#namespace_inheritance-instance_method for example usage.


#### Fix for XML::Builder

However, recognizing that we want `Builder`-created children to inherit namespaces, Builder now will set `namespace_inheritance=true` on the underlying document for both JRuby and CRuby. This means that, on CRuby, the pre-v1.12.0 behavior is restored.

Users who want to turn this behavior off may pass a keyword argument to the Builder constructor like so:

``` ruby
Nokogiri::XML::Builder.new(namespace_inheritance: false)
```

See https://nokogiri.org/rdoc/Nokogiri/XML/Builder.html#label-Namespace+inheritance for example usage.


#### Downstream gem maintainers

Note that any downstream gems may want to specifically omit Nokogiri v1.12.0--v1.12.3 from their dependency specification if they rely on child namespace inheritance:

``` ruby
Gem::Specification.new do |gem|
  # ...
  gem.add_runtime_dependency 'nokogiri', '!=1.12.3', '!=1.12.2', '!=1.12.1', '!=1.12.0'
  # ...
end
```


### Fixed

* [JRuby] Fix NPE in Schema parsing when an imported resource doesn't have a `systemId`. [[#2296](https://github.com/sparklemotion/nokogiri/issues/2296)] (Thanks, [@pepijnve](https://github.com/pepijnve)!)


## 1.12.3 / 2021-08-10

### Fixed

* [CRuby] Fix compilation of libgumbo on older systems with versions of GCC that give errors on C99-isms. Affected systems include RHEL6, RHEL7, and SLES12. [[#2302](https://github.com/sparklemotion/nokogiri/issues/2302)]


## 1.12.2 / 2021-08-04

### Fixed

* [CRuby] Ensure that C extension files in non-native gem installations are loaded using `require` and rely on `$LOAD_PATH` instead of using `require_relative`. This issue only exists when deleting shared libraries that exist outside the extensions directory, something users occasionally do to conserve disk space. [[#2300](https://github.com/sparklemotion/nokogiri/issues/2300)]


## 1.12.1 / 2021-08-03

### Fixed

* [CRuby] Fix compilation of libgumbo on BSD systems by avoiding GNU-isms. [[#2298](https://github.com/sparklemotion/nokogiri/issues/2298)]


## 1.12.0 / 2021-08-02

### Notable Addition: HTML5 Support (CRuby only)

__HTML5 support__ has been added (to CRuby only) by merging [Nokogumbo](https://github.com/rubys/nokogumbo) into Nokogiri. The Nokogumbo public API has been preserved, so this functionality is available under the `Nokogiri::HTML5` namespace. [[#2204](https://github.com/sparklemotion/nokogiri/issues/2204)]

Please note that HTML5 support is not available for JRuby in this version. However, we feel it is important to think about JRuby and we hope to work on this in the future. If you're interested in helping with HTML5 support on JRuby, please reach out to the maintainers by commenting on issue [#2227](https://github.com/sparklemotion/nokogiri/issues/2227).

Many thanks to Sam Ruby, Steve Checkoway, and Craig Barnes for creating and maintaining Nokogumbo and supporting the Gumbo HTML5 parser. They're now Nokogiri core contributors with all the powers and privileges pertaining thereto. 🙌


### Notable Change: `Nokogiri::HTML4` module and namespace

`Nokogiri::HTML` has been renamed to `Nokogiri::HTML4`, and `Nokogiri::HTML` is aliased to preserve backwards-compatibility. `Nokogiri::HTML` and `Nokogiri::HTML4` parse methods still use libxml2's (or NekoHTML's) HTML4 parser in the v1.12 release series. 

Take special note that if you rely on the class name of an object in your code, objects will now report a class of `Nokogiri::HTML4::Foo` where they previously reported `Nokogiri::HTML::Foo`. Instead of relying on the string returned by `Object#class`, prefer `Class#===` or `Object#is_a?` or `Object#instance_of?`.

Future releases of Nokogiri may deprecate `HTML` methods or otherwise change this behavior, so please start using `HTML4` in place of `HTML`.


### Added

* [CRuby] `Nokogiri::VERSION_INFO["libxslt"]["datetime_enabled"]` is a new boolean value which describes whether libxslt (or, more properly, libexslt) has compiled-in datetime support. This generally going to be `true`, but some distros ship without this support (e.g., some mingw UCRT-based packages, see https://github.com/msys2/MINGW-packages/pull/8957). See [#2272](https://github.com/sparklemotion/nokogiri/issues/2272) for more details.


### Changed

* Introduce a new constant, `Nokogiri::XML::ParseOptions::DEFAULT_XSLT`, which adds the libxslt-preferred options of `NOENT | DTDLOAD | DTDATTR | NOCDATA` to `ParseOptions::DEFAULT_XML`.
* `Nokogiri.XSLT` parses stylesheets using `ParseOptions::DEFAULT_XSLT`, which should make some edge-case XSL transformations match libxslt's default behavior. [[#1940](https://github.com/sparklemotion/nokogiri/issues/1940)]


### Fixed

* [CRuby] Namespaced attributes are handled properly when their parent node is reparented into another document. Previously, the namespace may have gotten dropped. [[#2228](https://github.com/sparklemotion/nokogiri/issues/2228)]
* [CRuby] Reparented nodes no longer inherit their parent's namespace. Previously, a node without a namespace was forced to adopt its parent's namespace. [[#1712](https://github.com/sparklemotion/nokogiri/issues/1712), [#425](https://github.com/sparklemotion/nokogiri/issues/425)]


### Improved

* [CRuby] Speed up (slightly) the compile time of packaged libraries `libiconv`, `libxml2`, and `libxslt` by using autoconf's `--disable-dependency-tracking` option. ("ruby" platform gem only.)


### Deprecated

* Deprecating Nokogumbo's `Nokogiri::HTML5.get`. This method will be removed in a future version of Nokogiri.


### Dependencies

* [CRuby] Upgrade mini_portile2 dependency from `~> 2.5.0` to `~> 2.6.1`. ("ruby" platform gem only.)


## 1.11.7 / 2021-06-02

### Fixed

* [CRuby] Backporting an upstream fix to XPath recursion depth limits which impacted some users of complex XPath queries. This issue is present in libxml 2.9.11 and 2.9.12. [[#2257](https://github.com/sparklemotion/nokogiri/issues/2257)]


## 1.11.6 / 2021-05-26

### Fixed

* [CRuby] `DocumentFragment#path` now does proper error-checking to handle behavior introduced in libxml > 2.9.10. In v1.11.4 and v1.11.5, calling `DocumentFragment#path` could result in a segfault.


## 1.11.5 / 2021-05-19

### Fixed

[Windows CRuby] Work around segfault at process exit on Windows when using libxml2 system DLLs.

libxml 2.9.12 introduced new behavior to avoid memory leaks when unloading libxml2 shared libraries (see [libxml/!66](https://gitlab.gnome.org/GNOME/libxml2/-/merge_requests/66)). Early testing caught this segfault on non-Windows platforms (see [#2059](https://github.com/sparklemotion/nokogiri/issues/2059) and [libxml@956534e](https://gitlab.gnome.org/GNOME/libxml2/-/commit/956534e02ef280795a187c16f6ac04e107f23c5d)) but it was incompletely fixed and is still an issue on Windows platforms that are using system DLLs.

We work around this by configuring libxml2 in this situation to use its default memory management functions. Note that if Nokogiri is not on Windows, or is not using shared system libraries, it will will continue to configure libxml2 to use Ruby's memory management functions. `Nokogiri::VERSION_INFO["libxml"]["memory_management"]` will allow you to verify when the default memory management functions are being used. [[#2241](https://github.com/sparklemotion/nokogiri/issues/2241)]


### Added

`Nokogiri::VERSION_INFO["libxml"]` now contains the key `"memory_management"` to declare whether libxml2 is using its `default` memory management functions, or whether it uses the memory management functions from `ruby`. See above for more details.


## 1.11.4 / 2021-05-14

### Security

[CRuby] Vendored libxml2 upgraded to v2.9.12 which addresses:

- [CVE-2019-20388](https://security.archlinux.org/CVE-2019-20388)
- [CVE-2020-24977](https://security.archlinux.org/CVE-2020-24977)
- [CVE-2021-3517](https://security.archlinux.org/CVE-2021-3517)
- [CVE-2021-3518](https://security.archlinux.org/CVE-2021-3518)
- [CVE-2021-3537](https://security.archlinux.org/CVE-2021-3537)
- [CVE-2021-3541](https://security.archlinux.org/CVE-2021-3541)

Note that two additional CVEs were addressed upstream but are not relevant to this release. [CVE-2021-3516](https://security.archlinux.org/CVE-2021-3516) via `xmllint` is not present in Nokogiri, and [CVE-2020-7595](https://security.archlinux.org/CVE-2020-7595) has been patched in Nokogiri since v1.10.8 (see [#1992](https://github.com/sparklemotion/nokogiri/issues/1992)).

Please see [nokogiri/GHSA-7rrm-v45f-jp64 ](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-7rrm-v45f-jp64) or [#2233](https://github.com/sparklemotion/nokogiri/issues/2233) for a more complete analysis of these CVEs and patches.


### Dependencies

* [CRuby] vendored libxml2 is updated from 2.9.10 to 2.9.12. (Note that 2.9.11 was skipped because it was superseded by 2.9.12 a few hours after its release.)


## 1.11.3 / 2021-04-07

### Fixed

* [CRuby] Passing non-`Node` objects to `Document#root=` now raises an `ArgumentError` exception. Previously this likely segfaulted. [[#1900](https://github.com/sparklemotion/nokogiri/issues/1900)]
* [JRuby] Passing non-`Node` objects to `Document#root=` now raises an `ArgumentError` exception. Previously this raised a `TypeError` exception.
* [CRuby] arm64/aarch64 systems (like Apple's M1) can now compile libxml2 and libxslt from source (though we continue to strongly advise users to install the native gems for the best possible experience)


## 1.11.2 / 2021-03-11

### Fixed

* [CRuby] `NodeSet` may now safely contain `Node` objects from multiple documents. Previously the GC lifecycle of the parent `Document` objects could lead to nodes being GCed while still in scope. [[#1952](https://github.com/sparklemotion/nokogiri/issues/1952#issuecomment-770856928)]
* [CRuby] Patch libxml2 to avoid "huge input lookup" errors on large CDATA elements. (See upstream [GNOME/libxml2#200](https://gitlab.gnome.org/GNOME/libxml2/-/issues/200) and [GNOME/libxml2!100](https://gitlab.gnome.org/GNOME/libxml2/-/merge_requests/100).) [[#2132](https://github.com/sparklemotion/nokogiri/issues/2132)].
* [CRuby+Windows] Enable Nokogumbo (and other downstream gems) to compile and link against `nokogiri.so` by including `LDFLAGS` in `Nokogiri::VERSION_INFO`. [[#2167](https://github.com/sparklemotion/nokogiri/issues/2167)]
* [CRuby] `{XML,HTML}::Document.parse` now invokes `#initialize` exactly once. Previously `#initialize` was invoked twice on each object.
* [JRuby] `{XML,HTML}::Document.parse` now invokes `#initialize` exactly once. Previously `#initialize` was not called, which was a problem for subclassing such as done by `Loofah`.


### Improved

* Reduce the number of object allocations needed when parsing an `HTML::DocumentFragment`. [[#2087](https://github.com/sparklemotion/nokogiri/issues/2087)] (Thanks, [@ashmaroli](https://github.com/ashmaroli)!)
* [JRuby] Update the algorithm used to calculate `Node#line` to be wrong less-often. The underlying parser, Xerces, does not track line numbers, and so we've always used a hacky solution for this method. [[#1223](https://github.com/sparklemotion/nokogiri/issues/1223), [#2177](https://github.com/sparklemotion/nokogiri/issues/2177)]
* Introduce `--enable-system-libraries` and `--disable-system-libraries` flags to `extconf.rb`. These flags provide the same functionality as `--use-system-libraries` and the `NOKOGIRI_USE_SYSTEM_LIBRARIES` environment variable, but are more idiomatic. [[#2193](https://github.com/sparklemotion/nokogiri/issues/2193)] (Thanks, [@eregon](https://github.com/eregon)!)
* [TruffleRuby] `--disable-static` is now the default on TruffleRuby when the packaged libraries are used. This is more flexible and compiles faster. (Note, though, that the default on TR is still to use system libraries.) [[#2191](https://github.com/sparklemotion/nokogiri/issues/2191#issuecomment-780724627), [#2193](https://github.com/sparklemotion/nokogiri/issues/2193)] (Thanks, [@eregon](https://github.com/eregon)!)


### Changed

* `Nokogiri::XML::Path` is now a Module (previously it has been a Class). It has been acting solely as a Module since v1.0.0. See [8461c74](https://github.com/sparklemotion/nokogiri/commit/8461c74).


## 1.11.1 / 2021-01-06

### Fixed

* [CRuby] If `libxml-ruby` is loaded before `nokogiri`, the SAX and Push parsers no longer call `libxml-ruby`'s handlers. Instead, they defensively override the libxml2 global handler before parsing. [[#2168](https://github.com/sparklemotion/nokogiri/issues/2168)]


## 1.11.0 / 2021-01-03

### Notes

#### Faster, more reliable installation: Native Gems for Linux and OSX/Darwin

"Native gems" contain pre-compiled libraries for a specific machine architecture. On supported platforms, this removes the need for compiling the C extension and the packaged libraries. This results in **much faster installation** and **more reliable installation**, which as you probably know are the biggest headaches for Nokogiri users. 

We've been shipping native Windows gems since 2009, but starting in v1.11.0 we are also shipping native gems for these platforms:

- Linux: `x86-linux` and `x86_64-linux` -- including musl platforms like alpine
- OSX/Darwin: `x86_64-darwin` and `arm64-darwin`

We'd appreciate your thoughts and feedback on this work at [#2075](https://github.com/sparklemotion/nokogiri/issues/2075).


### Dependencies

#### Ruby

This release introduces support for Ruby 2.7 and 3.0 in the precompiled native gems.

This release ends support for:

* Ruby 2.3, for which [official support ended on 2019-03-31](https://www.ruby-lang.org/en/news/2019/03/31/support-of-ruby-2-3-has-ended/) [[#1886](https://github.com/sparklemotion/nokogiri/issues/1886)] (Thanks [@ashmaroli](https://github.com/ashmaroli)!)
* Ruby 2.4, for which [official support ended on 2020-04-05](https://www.ruby-lang.org/en/news/2020/04/05/support-of-ruby-2-4-has-ended/)
* JRuby 9.1, which is the Ruby 2.3-compatible release.


#### Gems

* Explicitly add racc as a runtime dependency. [[#1988](https://github.com/sparklemotion/nokogiri/issues/1988)] (Thanks, [@voxik](https://github.com/voxik)!)
* [MRI] Upgrade mini_portile2 dependency from `~> 2.4.0` to `~> 2.5.0` [[#2005](https://github.com/sparklemotion/nokogiri/issues/2005)] (Thanks, [@alejandroperea](https://github.com/alejandroperea)!)


### Security

See note below about CVE-2020-26247 in the "Changed" subsection entitled "XML::Schema parsing treats input as untrusted by default".


### Added

* Add Node methods for manipulating "keyword attributes" (for example, `class` and `rel`): `#kwattr_values`, `#kwattr_add`, `#kwattr_append`, and `#kwattr_remove`. [[#2000](https://github.com/sparklemotion/nokogiri/issues/2000)]
* Add support for CSS queries `a:has(> b)`, `a:has(~ b)`, and `a:has(+ b)`. [[#688](https://github.com/sparklemotion/nokogiri/issues/688)] (Thanks, [@jonathanhefner](https://github.com/jonathanhefner)!)
* Add `Node#value?` to better match expected semantics of a Hash-like object. [[#1838](https://github.com/sparklemotion/nokogiri/issues/1838), [#1840](https://github.com/sparklemotion/nokogiri/issues/1840)] (Thanks, [@MatzFan](https://github.com/MatzFan)!)
* [CRuby] Add `Nokogiri::XML::Node#line=` for use by downstream libs like nokogumbo. [[#1918](https://github.com/sparklemotion/nokogiri/issues/1918)] (Thanks, [@stevecheckoway](https://github.com/stevecheckoway)!)
* `nokogiri.gemspec` is back after a 10-year hiatus. We still prefer you use the official releases, but `main` is pretty stable these days, and YOLO.


### Performance

* [CRuby] The CSS `~=` operator and class selector `.` are about 2x faster. [[#2137](https://github.com/sparklemotion/nokogiri/issues/2137), [#2135](https://github.com/sparklemotion/nokogiri/issues/2135)]
* [CRuby] Patch libxml2 to call `strlen` from `xmlStrlen` rather than the naive implementation, because `strlen` is generally optimized for the architecture. [[#2144](https://github.com/sparklemotion/nokogiri/issues/2144)] (Thanks, [@ilyazub](https://github.com/ilyazub)!)
* Improve performance of some namespace operations. [[#1916](https://github.com/sparklemotion/nokogiri/issues/1916)] (Thanks, [@ashmaroli](https://github.com/ashmaroli)!)
* Remove unnecessary array allocations from Node serialization methods [[#1911](https://github.com/sparklemotion/nokogiri/issues/1911)] (Thanks, [@ashmaroli](https://github.com/ashmaroli)!)
* Avoid creation of unnecessary zero-length String objects. [[#1970](https://github.com/sparklemotion/nokogiri/issues/1970)] (Thanks, [@ashmaroli](https://github.com/ashmaroli)!)
* Always compile libxml2 and libxslt with '-O2' [[#2022](https://github.com/sparklemotion/nokogiri/issues/2022), [#2100](https://github.com/sparklemotion/nokogiri/issues/2100)] (Thanks, [@ilyazub](https://github.com/ilyazub)!)
* [JRuby] Lots of code cleanup and performance improvements. [[#1934](https://github.com/sparklemotion/nokogiri/issues/1934)] (Thanks, [@kares](https://github.com/kares)!)
* [CRuby] `RelaxNG.from_document` no longer leaks memory. [[#2114](https://github.com/sparklemotion/nokogiri/issues/2114)]


### Improved

* [CRuby] Handle incorrectly-closed HTML comments as WHATWG recommends for browsers. [[#2058](https://github.com/sparklemotion/nokogiri/issues/2058)] (Thanks to HackerOne user [mayflower](https://hackerone.com/mayflower?type=user) for reporting this!)
* `{HTML,XML}::Document#parse` now accept `Pathname` objects. Previously this worked only if the referenced file was less than 4096 bytes long; longer files resulted in undefined behavior because the `read` method would be repeatedly invoked. [[#1821](https://github.com/sparklemotion/nokogiri/issues/1821), [#2110](https://github.com/sparklemotion/nokogiri/issues/2110)] (Thanks, [@doriantaylor](https://github.com/doriantaylor) and [@phokz](https://github.com/phokz)!)
* [CRuby] Nokogumbo builds faster because it can now use header files provided by Nokogiri. [[#1788](https://github.com/sparklemotion/nokogiri/issues/1788)] (Thanks, [@stevecheckoway](https://github.com/stevecheckoway)!)
* Add `frozen_string_literal: true` magic comment to all `lib` files. [[#1745](https://github.com/sparklemotion/nokogiri/issues/1745)] (Thanks, [@oniofchaos](https://github.com/oniofchaos)!)
* [JRuby] Clean up deprecated calls into JRuby. [[#2027](https://github.com/sparklemotion/nokogiri/issues/2027)] (Thanks, [@headius](https://github.com/headius)!)


### Fixed

* HTML Parsing in "strict" mode (i.e., the `RECOVER` parse option not set) now correctly raises a `XML::SyntaxError` exception. Previously the value of the `RECOVER` bit was being ignored by CRuby and was misinterpreted by JRuby. [[#2130](https://github.com/sparklemotion/nokogiri/issues/2130)]
* The CSS `~=` operator now correctly handles non-space whitespace in the `class` attribute. commit e45dedd
* The switch to turn off the CSS-to-XPath cache is now thread-local, rather than being shared mutable state. [[#1935](https://github.com/sparklemotion/nokogiri/issues/1935)]
* The Node methods `add_previous_sibling`, `previous=`, `before`, `add_next_sibling`, `next=`, `after`, `replace`, and `swap` now correctly use their parent as the context node for parsing markup. These methods now also raise a `RuntimeError` if they are called on a node with no parent. [[nokogumbo#160](https://github.com/rubys/nokogumbo/issues/160)]
* [JRuby] `XML::Schema` XSD validation errors are captured in `XML::Schema#errors`. These errors were previously ignored.
* [JRuby] Standardize reading from IO like objects, including StringIO. [[#1888](https://github.com/sparklemotion/nokogiri/issues/1888), [#1897](https://github.com/sparklemotion/nokogiri/issues/1897)]
* [JRuby] Fix how custom XPath function namespaces are inferred to be less naive. [[#1890](https://github.com/sparklemotion/nokogiri/issues/1890), [#2148](https://github.com/sparklemotion/nokogiri/issues/2148)]
* [JRuby] Clarify exception message when custom XPath functions can't be resolved.
* [JRuby] Comparison of Node to Document with `Node#<=>` now matches CRuby/libxml2 behavior.
* [CRuby] Syntax errors are now correctly captured in `Document#errors` for short HTML documents. Previously the SAX parser used for encoding detection was clobbering libxml2's global error handler.
* [CRuby] Fixed installation on AIX with respect to `vasprintf`. [[#1908](https://github.com/sparklemotion/nokogiri/issues/1908)]
* [CRuby] On some platforms, avoid symbol name collision with glibc's `canonicalize`. [[#2105](https://github.com/sparklemotion/nokogiri/issues/2105)]
* [Windows Visual C++] Fixed compiler warnings and errors. [[#2061](https://github.com/sparklemotion/nokogiri/issues/2061), [#2068](https://github.com/sparklemotion/nokogiri/issues/2068)]
* [CRuby] Fixed Nokogumbo integration which broke in the v1.11.0 release candidates. [[#1788](https://github.com/sparklemotion/nokogiri/issues/1788)] (Thanks, [@stevecheckoway](https://github.com/stevecheckoway)!)
* [JRuby] Fixed document encoding regression in v1.11.0 release candidates. [[#2080](https://github.com/sparklemotion/nokogiri/issues/2080), [#2083](https://github.com/sparklemotion/nokogiri/issues/2083)] (Thanks, [@thbar](https://github.com/thbar)!)


### Removed

* The internal method `Nokogiri::CSS::Parser.cache_on=` has been removed. Use `.set_cache` if you need to muck with the cache internals.
* The class method `Nokogiri::CSS::Parser.parse` has been removed. This was originally deprecated in 2009 in 13db61b. Use `Nokogiri::CSS.parse` instead.


### Changed

#### `XML::Schema` input is now "untrusted" by default

Address [CVE-2020-26247](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-vr8q-g5c7-m54m).

In Nokogiri versions <= 1.11.0.rc3, XML Schemas parsed by `Nokogiri::XML::Schema` were **trusted** by default, allowing external resources to be accessed over the network, potentially enabling XXE or SSRF attacks.

This behavior is counter to the security policy intended by Nokogiri maintainers, which is to treat all input as **untrusted** by default whenever possible.

Please note that this security fix was pushed into a new minor version, 1.11.x, rather than a patch release to the 1.10.x branch, because it is a breaking change for some schemas and the risk was assessed to be "Low Severity".

More information and instructions for enabling "trusted input" behavior in v1.11.0.rc4 and later is available at the [public advisory](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-vr8q-g5c7-m54m).


#### HTML parser now obeys the `strict` or `norecover` parsing option

(Also noted above in the "Fixed" section) HTML Parsing in "strict" mode (i.e., the `RECOVER` parse option not set) now correctly raises a `XML::SyntaxError` exception. Previously the value of the `RECOVER` bit was being ignored by CRuby and was misinterpreted by JRuby.

If you're using the default parser options, you will be unaffected by this fix. If you're passing `strict` or `norecover` to your HTML parser call, you may be surprised to see that the parser now fails to recover and raises a `XML::SyntaxError` exception. Given the number of HTML documents on the internet that libxml2 would consider to be ill-formed, this is probably not what you want, and you can omit setting that parse option to restore the behavior that you have been relying upon.

Apologies to anyone inconvenienced by this breaking bugfix being present in a minor release, but I felt it was appropriate to introduce this fix because it's straightforward to fix any code that has been relying on this buggy behavior.


#### `VersionInfo`, the output of `nokogiri -v`, and related constants

This release changes the metadata provided in `Nokogiri::VersionInfo` which also affects the output of `nokogiri -v`. Some related constants have also been changed. If you're using `VersionInfo` programmatically, or relying on constants related to underlying library versions, please read the detailed changes for `Nokogiri::VersionInfo` at [#2139](https://github.com/sparklemotion/nokogiri/issues/2139) and accept our apologies for the inconvenience.


## 1.10.10 / 2020-07-06

### Features

* [MRI] Cross-built Windows gems now support Ruby 2.7 [[#2029](https://github.com/sparklemotion/nokogiri/issues/2029)]. Note that prior to this release, the v1.11.x prereleases provided this support.


## 1.10.9 / 2020-03-01

### Fixed

* [MRI] Raise an exception when Nokogiri detects a specific libxml2 edge case involving blank Schema nodes wrapped by Ruby objects that would cause a segfault. Currently no fix is available upstream, so we're preventing a dangerous operation and informing users to code around it if possible. [[#1985](https://github.com/sparklemotion/nokogiri/issues/1985), [#2001](https://github.com/sparklemotion/nokogiri/issues/2001)]
* [JRuby] Change `NodeSet#to_a` to return a RubyArray instead of Object, for compilation under JRuby 9.2.9 and later. [[#1968](https://github.com/sparklemotion/nokogiri/issues/1968), [#1969](https://github.com/sparklemotion/nokogiri/issues/1969)] (Thanks, [@headius](https://github.com/headius)!)


## 1.10.8 / 2020-02-10

### Security

[MRI] Pulled in upstream patch from libxml that addresses CVE-2020-7595. Full details are available in [#1992](https://github.com/sparklemotion/nokogiri/issues/1992). Note that this patch is not yet (as of 2020-02-10) in an upstream release of libxml.


## 1.10.7 / 2019-12-03

### Fixed

* [MRI] Ensure the patch applied in v1.10.6 works with GNU `patch`. [[#1954](https://github.com/sparklemotion/nokogiri/issues/1954)]


## 1.10.6 / 2019-12-03

### Fixed

* [MRI] Fix FreeBSD installation of vendored libxml2. [[#1941](https://github.com/sparklemotion/nokogiri/issues/1941), [#1953](https://github.com/sparklemotion/nokogiri/issues/1953)] (Thanks, [@nurse](https://github.com/nurse)!)


## 1.10.5 / 2019-10-31

### Security

[MRI] Vendored libxslt upgraded to v1.1.34 which addresses three CVEs for libxslt:

* CVE-2019-13117
* CVE-2019-13118
* CVE-2019-18197
* CVE-2019-19956

More details are available at [#1943](https://github.com/sparklemotion/nokogiri/issues/1943).


### Dependencies

* [MRI] vendored libxml2 is updated from 2.9.9 to 2.9.10
* [MRI] vendored libxslt is updated from 1.1.33 to 1.1.34


## 1.10.4 / 2019-08-11

### Security

Address CVE-2019-5477 ([#1915](https://github.com/sparklemotion/nokogiri/issues/1915)).

A command injection vulnerability in Nokogiri v1.10.3 and earlier allows commands to be executed in a subprocess by Ruby's `Kernel.open` method. Processes are vulnerable only if the undocumented method `Nokogiri::CSS::Tokenizer#load_file` is being passed untrusted user input.

This vulnerability appears in code generated by the Rexical gem versions v1.0.6 and earlier. Rexical is used by Nokogiri to generate lexical scanner code for parsing CSS queries. The underlying vulnerability was addressed in Rexical v1.0.7 and Nokogiri upgraded to this version of Rexical in Nokogiri v1.10.4.

This CVE's public notice is [#1915](https://github.com/sparklemotion/nokogiri/issues/1915)


## 1.10.3 / 2019-04-22

### Security

[MRI] Pulled in upstream patch from libxslt that addresses CVE-2019-11068. Full details are available in [#1892](https://github.com/sparklemotion/nokogiri/issues/1892). Note that this patch is not yet (as of 2019-04-22) in an upstream release of libxslt.


## 1.10.2 / 2019-03-24

### Security

* [MRI] Remove support from vendored libxml2 for future script macros. [[#1871](https://github.com/sparklemotion/nokogiri/issues/1871)]
* [MRI] Remove support from vendored libxml2 for server-side includes within attributes. [[#1877](https://github.com/sparklemotion/nokogiri/issues/1877)]


### Fixed

* [JRuby] Fix node ownership in duplicated documents. [[#1060](https://github.com/sparklemotion/nokogiri/issues/1060)]
* [JRuby] Rethrow exceptions caught by Java SAX handler. [[#1847](https://github.com/sparklemotion/nokogiri/issues/1847), [#1872](https://github.com/sparklemotion/nokogiri/issues/1872)] (Thanks, [@adjam](https://github.com/adjam)!)


## 1.10.1 / 2019-01-13

### Added

* [MRI] During installation, handle Xcode 10's new library path. [[#1801](https://github.com/sparklemotion/nokogiri/issues/1801), [#1851](https://github.com/sparklemotion/nokogiri/issues/1851)] (Thanks, [@mlj](https://github.com/mlj) and [@deepj](https://github.com/deepj)!)
* Avoid unnecessary creation of `Proc`s in many methods. [[#1776](https://github.com/sparklemotion/nokogiri/issues/1776)] (Thanks, [@chopraanmol1](https://github.com/chopraanmol1)!)


### Fixed

* CSS selector `:has()` now correctly matches against any descendant. Previously this selector matched against only direct children). [[#350](https://github.com/sparklemotion/nokogiri/issues/350)] (Thanks, [@Phrogz](https://github.com/Phrogz)!)
* `NodeSet#attr` now returns `nil` if it's empty. Previously this raised a NoMethodError.
* [MRI] XPath errors are no longer suppressed during `XSLT::Stylesheet#transform`. Previously these errors were suppressed which led to silent failures and a subsequent segfault. [[#1802](https://github.com/sparklemotion/nokogiri/issues/1802)]


## 1.10.0 / 2019-01-04

### Added

* [MRI] Cross-built Windows gems now support Ruby 2.6 [[#1842](https://github.com/sparklemotion/nokogiri/issues/1842), [#1850](https://github.com/sparklemotion/nokogiri/issues/1850)]


### Dependencies

* This release ends support for Ruby 2.2, for which [official support ended on 2018-03-31](https://www.ruby-lang.org/en/news/2018/06/20/support-of-ruby-2-2-has-ended/) [[#1841](https://github.com/sparklemotion/nokogiri/issues/1841)]
* This release ends support for JRuby 1.7, for which [official support ended on 2017-11-21](https://github.com/jruby/jruby/issues/4112) [[#1741](https://github.com/sparklemotion/nokogiri/issues/1741)]
* [MRI] libxml2 is updated from 2.9.8 to 2.9.9
* [MRI] libxslt is updated from 1.1.32 to 1.1.33


## 1.9.1 / 2018-12-17

### Fixed

* Fix a bug introduced in v1.9.0 where `XML::DocumentFragment#dup` no longer returned an instance of the callee's class, instead always returning an `XML::DocumentFragment`. This notably broke any subclass of `XML::DocumentFragment` including `HTML::DocumentFragment` as well as the Loofah gem's `Loofah::HTML::DocumentFragment`. [[#1846](https://github.com/sparklemotion/nokogiri/issues/1846)]


## 1.9.0 / 2018-12-17

### Security

* [JRuby] Upgrade Xerces dependency from 2.11.0 to 2.12.0 to address upstream vulnerability CVE-2012-0881 [[#1831](https://github.com/sparklemotion/nokogiri/issues/1831)] (Thanks [@grajagandev](https://github.com/grajagandev) for reporting.)


### Improved

* Decrease installation size by removing many unneeded files (e.g., `/test`) from the packaged gems. [[#1719](https://github.com/sparklemotion/nokogiri/issues/1719)] (Thanks, [@stevecrozz](https://github.com/stevecrozz)!)


### Added

* `XML::Attr#value=` allows HTML node attribute values to be set to either a blank string or an empty boolean attribute. [[#1800](https://github.com/sparklemotion/nokogiri/issues/1800)]
* Introduce `XML::Node#wrap` which does what `XML::NodeSet#wrap` has always done, but for a single node. [[#1531](https://github.com/sparklemotion/nokogiri/issues/1531)] (Thanks, [@ethirajsrinivasan](https://github.com/ethirajsrinivasan)!)
* [MRI] Improve installation experience on macOS High Sierra (Darwin). [[#1812](https://github.com/sparklemotion/nokogiri/issues/1812), [#1813](https://github.com/sparklemotion/nokogiri/issues/1813)] (Thanks, [@gpakosz](https://github.com/gpakosz) and [@nurse](https://github.com/nurse)!)
* [MRI] `Node#dup` supports copying a node directly to a new document. See the method documentation for details.
* [MRI] `DocumentFragment#dup` is now more memory-efficient, avoiding making unnecessary copies. [[#1063](https://github.com/sparklemotion/nokogiri/issues/1063)]
* [JRuby] `NodeSet` has been rewritten to improve performance! [[#1795](https://github.com/sparklemotion/nokogiri/issues/1795)]


### Fixed

* `NodeSet#each` now returns `self` instead of zero. [[#1822](https://github.com/sparklemotion/nokogiri/issues/1822)] (Thanks, [@olehif](https://github.com/olehif)!)
* [MRI] Address a memory leak when using `XML::Builder` to create nodes with namespaces. [[#1810](https://github.com/sparklemotion/nokogiri/issues/1810)]
* [MRI] Address a memory leak when unparenting a DTD. [[#1784](https://github.com/sparklemotion/nokogiri/issues/1784)] (Thanks, [@stevecheckoway](https://github.com/stevecheckoway)!)
* [MRI] Use `RbConfig::CONFIG` instead of `::MAKEFILE_CONFIG` to fix installations that use Makefile macros. [[#1820](https://github.com/sparklemotion/nokogiri/issues/1820)] (Thanks, [@nobu](https://github.com/nobu)!)
* [JRuby] Decrease large memory usage when making nested XPath queries. [[#1749](https://github.com/sparklemotion/nokogiri/issues/1749)]
* [JRuby] Fix failing tests on JRuby 9.2.x
* [JRuby] Fix default namespaces in nodes reparented into a different document [[#1774](https://github.com/sparklemotion/nokogiri/issues/1774)]
* [JRuby] Fix support for Java 9. [[#1759](https://github.com/sparklemotion/nokogiri/issues/1759)] (Thanks, [@Taywee](https://github.com/Taywee)!)


### Dependencies

* [MRI] Upgrade mini_portile2 dependency from `~> 2.3.0` to `~> 2.4.0`


## 1.8.5 / 2018-10-04

### Security

[MRI] Pulled in upstream patches from libxml2 that address CVE-2018-14404 and CVE-2018-14567. Full details are available in [#1785](https://github.com/sparklemotion/nokogiri/issues/1785). Note that these patches are not yet (as of 2018-10-04) in an upstream release of libxml2.


### Fixed

* [MRI] Fix regression in installation when building against system libraries, where some systems would not be able to find libxml2 or libxslt when present. (Regression introduced in v1.8.3.) [[#1722](https://github.com/sparklemotion/nokogiri/issues/1722)]
* [JRuby] Fix node reparenting when the destination doc is empty. [[#1773](https://github.com/sparklemotion/nokogiri/issues/1773)]


## 1.8.4 / 2018-07-03

### Fixed

* [MRI] Fix memory leak when creating nodes with namespaces. (Introduced in v1.5.7) [[#1771](https://github.com/sparklemotion/nokogiri/issues/1771)]


## 1.8.3 / 2018-06-16

### Security

[MRI] Behavior in libxml2 has been reverted which caused CVE-2018-8048 (loofah gem), CVE-2018-3740 (sanitize gem), and CVE-2018-3741 (rails-html-sanitizer gem). The commit in question is here:

> https://github.com/GNOME/libxml2/commit/960f0e2

and more information is available about this commit and its impact here:

> https://github.com/flavorjones/loofah/issues/144

This release simply reverts the libxml2 commit in question to protect users of Nokogiri's vendored libraries from similar vulnerabilities.

If you're offended by what happened here, I'd kindly ask that you comment on the upstream bug report here:

> https://bugzilla.gnome.org/show_bug.cgi?id=769760


### More Security

[MRI] Vendored libxml2 upgraded to v2.9.8 which addresses CVE-2016-9318 [[#1582](https://github.com/sparklemotion/nokogiri/issues/1582)].


### Dependencies

* [MRI] libxml2 is updated from 2.9.7 to 2.9.8


### Added

* `Node#classes`, `#add_class`, `#append_class`, and `#remove_class` are added.
* `NodeSet#append_class` is added.
* `NodeSet#remove_attribute` is a new alias for `NodeSet#remove_attr`.
* `NodeSet#each` now returns an `Enumerator` when no block is passed (Thanks, [@park53kr](https://github.com/park53kr)!)
* [JRuby] General improvements in JRuby implementation (Thanks, [@kares](https://github.com/kares)!)


### Fixed

* CSS attribute selectors now gracefully handle queries using integers. [[#711](https://github.com/sparklemotion/nokogiri/issues/711)]
* Handle ASCII-8BIT encoding on fragment input [[#553](https://github.com/sparklemotion/nokogiri/issues/553)]
* Handle non-string return values within `Reader` [[#898](https://github.com/sparklemotion/nokogiri/issues/898)]
* [JRuby] Allow `Node#replace` to insert Comment and CDATA nodes. [[#1666](https://github.com/sparklemotion/nokogiri/issues/1666)]
* [JRuby] Stability and speed improvements to `Node`, `Sax::PushParser`, and the JRuby implementation [[#1708](https://github.com/sparklemotion/nokogiri/issues/1708), [#1710](https://github.com/sparklemotion/nokogiri/issues/1710), [#1501](https://github.com/sparklemotion/nokogiri/issues/1501)]


## 1.8.2 / 2018-01-29

### Security

[MRI] The update of vendored libxml2 from 2.9.5 to 2.9.7 addresses at least one published vulnerability, CVE-2017-15412. [[#1714](https://github.com/sparklemotion/nokogiri/issues/1714) has complete details]


### Dependencies

* [MRI] libxml2 is updated from 2.9.5 to 2.9.7
* [MRI] libxslt is updated from 1.1.30 to 1.1.32


### Added

* [MRI] OpenBSD installation should be a bit easier now. [[#1685](https://github.com/sparklemotion/nokogiri/issues/1685)] (Thanks, [@jeremyevans](https://github.com/jeremyevans)!)
* [MRI] Cross-built Windows gems now support Ruby 2.5


### Fixed

* `Node#serialize` once again returns UTF-8-encoded strings. [[#1659](https://github.com/sparklemotion/nokogiri/issues/1659)]
* [JRuby] made SAX parsing of characters consistent with C implementation [[#1676](https://github.com/sparklemotion/nokogiri/issues/1676)] (Thanks, [[@andrew](https://github.com/andrew)-aladev](https://github.com/andrew-aladev)!)
* [MRI] Predefined entities, when inspected, no longer cause a segfault. [[#1238](https://github.com/sparklemotion/nokogiri/issues/1238)]


## 1.8.1 / 2017-09-19

### Dependencies

* [MRI] libxml2 is updated from 2.9.4 to 2.9.5.
* [MRI] libxslt is updated from 1.1.29 to 1.1.30.
* [MRI] optional dependency on the pkg-config gem has had its constraint loosened to `~> 1.1` (from `~> 1.1.7`). [[#1660](https://github.com/sparklemotion/nokogiri/issues/1660)]
* [MRI] Upgrade mini_portile2 dependency from `~> 2.2.0` to `~> 2.3.0`, which will validate checksums on the vendored libxml2 and libxslt tarballs before using them.


### Fixed

* `NodeSet#first` with an integer argument longer than the length of the `NodeSet` now correctly clamps the length of the returned `NodeSet` to the original length. [[#1650](https://github.com/sparklemotion/nokogiri/issues/1650)] (Thanks, [@Derenge](https://github.com/Derenge)!)
* [MRI] Ensure CData.new raises TypeError if the `content` argument is not implicitly convertible into a string. [[#1669](https://github.com/sparklemotion/nokogiri/issues/1669)]


## 1.8.0 / 2017-06-04

### Dependencies

This release ends support for Ruby 2.1 on Windows in the `x86-mingw32` and `x64-mingw32` platform gems (containing pre-compiled DLLs). Official support ended for Ruby 2.1 on 2017-04-01.

Please note that this deprecation note only applies to the precompiled Windows gems. Ruby 2.1 continues to be supported (for now) in the default gem when compiled on installation.


### Dependencies

* [Windows] Upgrade iconv from 1.14 to 1.15 (unless --use-system-libraries)
* [Windows] Upgrade zlib from 1.2.8 to 1.2.11 (unless --use-system-libraries)
* [MRI] Upgrade rake-compiler dependency from 0.9.2 to 1.0.3
* [MRI] Upgrade mini-portile2 dependency from `~> 2.1.0` to `~> 2.2.0`
* [JRuby] Removed support for `jruby --1.8` code paths. [[#1607](https://github.com/sparklemotion/nokogiri/issues/1607)] (Thanks, [@kares](https://github.com/kares)!)
* [MRI Windows] Retrieve zlib source from http://zlib.net/fossils to avoid deprecation issues going forward. See [#1632](https://github.com/sparklemotion/nokogiri/issues/1632) for details around this problem.

### Added

* `NodeSet#clone` is now an alias for `NodeSet#dup` [[#1503](https://github.com/sparklemotion/nokogiri/issues/1503)] (Thanks, [@stephankaag](https://github.com/stephankaag)!)
* Allow Processing Instructions and Comments as children of a document root. [[#1033](https://github.com/sparklemotion/nokogiri/issues/1033)] (Thanks, [@windwiny](https://github.com/windwiny)!)
* [MRI] `PushParser#replace_entities` and `#replace_entities=` will control whether entities are replaced or not. [[#1017](https://github.com/sparklemotion/nokogiri/issues/1017)] (Thanks, [@spraints](https://github.com/spraints)!)
* [MRI] `SyntaxError#to_s` now includes line number, column number, and log level if made available by the parser. [[#1304](https://github.com/sparklemotion/nokogiri/issues/1304), [#1637](https://github.com/sparklemotion/nokogiri/issues/1637)] (Thanks, [@spk](https://github.com/spk) and [@ccarruitero](https://github.com/ccarruitero)!)
* [MRI] Cross-built Windows gems now support Ruby 2.4
* [MRI] Support for frozen string literals. [[#1413](https://github.com/sparklemotion/nokogiri/issues/1413)]
* [MRI] Support for installing Nokogiri on a machine in FIPS-enabled mode [[#1544](https://github.com/sparklemotion/nokogiri/issues/1544)]
* [MRI] Vendored libraries are verified with SHA-256 hashes (formerly some MD5 hashes were used) [[#1544](https://github.com/sparklemotion/nokogiri/issues/1544)]
* [JRuby] (performance) remove unnecessary synchronization of class-cache [[#1563](https://github.com/sparklemotion/nokogiri/issues/1563)] (Thanks, [@kares](https://github.com/kares)!)
* [JRuby] (performance) remove unnecessary cloning of objects in XPath searches [[#1563](https://github.com/sparklemotion/nokogiri/issues/1563)] (Thanks, [@kares](https://github.com/kares)!)
* [JRuby] (performance) more performance improvements, particularly in XPath, Reader, XmlNode, and XmlNodeSet [[#1597](https://github.com/sparklemotion/nokogiri/issues/1597)] (Thanks, [@kares](https://github.com/kares)!)


### Fixed

* `HTML::SAX::Parser#parse_io` now correctly parses HTML and not XML [[#1577](https://github.com/sparklemotion/nokogiri/issues/1577)] (Thanks for the test case, [@gregors](https://github.com/gregors)!)
* Support installation on systems with a `lib64` site config. [[#1562](https://github.com/sparklemotion/nokogiri/issues/1562)]
* [MRI] on OpenBSD, do not require gcc if using system libraries [[#1515](https://github.com/sparklemotion/nokogiri/issues/1515)] (Thanks, [@jeremyevans](https://github.com/jeremyevans)!)
* [MRI] `XML::Attr.new` checks type of Document arg to prevent segfaults. [[#1477](https://github.com/sparklemotion/nokogiri/issues/1477)]
* [MRI] Prefer xmlCharStrdup (and friends) to strdup (and friends), which can cause problems on some platforms. [[#1517](https://github.com/sparklemotion/nokogiri/issues/1517)] (Thanks, [@jeremy](https://github.com/jeremy)!)
* [JRuby] correctly append a text node before another text node [[#1318](https://github.com/sparklemotion/nokogiri/issues/1318)] (Thanks, [@jkraemer](https://github.com/jkraemer)!)
* [JRuby] custom xpath functions returning an integer now work correctly [[#1595](https://github.com/sparklemotion/nokogiri/issues/1595)] (Thanks, [@kares](https://github.com/kares)!)
* [JRuby] serializing (`#to_html`, `#to_s`, et al) a document with explicit encoding now works correctly. [[#1281](https://github.com/sparklemotion/nokogiri/issues/1281), [#1440](https://github.com/sparklemotion/nokogiri/issues/1440)] (Thanks, [@kares](https://github.com/kares)!)
* [JRuby] `XML::Reader` now returns parse errors [[#1586](https://github.com/sparklemotion/nokogiri/issues/1586)] (Thanks, [@kares](https://github.com/kares)!)
* [JRuby] Empty `NodeSet`s are now decorated properly. [[#1319](https://github.com/sparklemotion/nokogiri/issues/1319)] (Thanks, [@kares](https://github.com/kares)!)
* [JRuby] Merged nodes no longer results in Java exceptions during XPath queries. [[#1320](https://github.com/sparklemotion/nokogiri/issues/1320)] (Thanks, [@kares](https://github.com/kares)!)


## 1.7.2 / 2017-05-09

### Security

[MRI] Upstream libxslt patches are applied to the vendored libxslt 1.1.29 which address CVE-2017-5029 and CVE-2016-4738.

For more information:

* [#1634](https://github.com/sparklemotion/nokogiri/issues/1634)
* http://people.canonical.com/~ubuntu-security/cve/2017/CVE-2017-5029.html
* http://people.canonical.com/~ubuntu-security/cve/2016/CVE-2016-4738.html


## 1.7.1 / 2017-03-19

### Security

[MRI] Upstream libxml2 patches are applied to the vendored libxml 2.9.4 which address CVE-2016-4658 and CVE-2016-5131.

For more information:

* [#1615](https://github.com/sparklemotion/nokogiri/issues/1615)
* http://people.canonical.com/~ubuntu-security/cve/2016/CVE-2016-4658.html
* http://people.canonical.com/~ubuntu-security/cve/2016/CVE-2016-5131.html


## 1.7.0.1 / 2017-01-04

### Fixed

* Fix OpenBSD support. ([#1569](https://github.com/sparklemotion/nokogiri/issues/1569)) (related to [#1543](https://github.com/sparklemotion/nokogiri/issues/1543))


## 1.7.0 / 2016-12-26

### Added

* Remove deprecation warnings in Ruby 2.4.0 ([#1545](https://github.com/sparklemotion/nokogiri/issues/1545)) (Thanks, [@matthewd](https://github.com/matthewd)!)
* Support egcc compiler on OpenBSD ([#1543](https://github.com/sparklemotion/nokogiri/issues/1543)) (Thanks, [@frenkel](https://github.com/frenkel) and [@knu](https://github.com/knu)!)


### Dependencies

This release ends support for:

* Ruby 1.9.2, for which official support ended on 2014-07-31
* Ruby 1.9.3, for which official support ended on 2015-02-23
* Ruby 2.0.0, for which official support ended on 2016-02-24
* MacRuby, which hasn't been actively supported since 2015-01-13 (see https://github.com/MacRuby/MacRuby/commit/f76b9d6e99c18236db617e8aceb12c27d593a483)


## 1.6.8.1 / 2016-10-03

### Dependencies

Removes required dependency on the `pkg-config` gem. This dependency
was introduced in v1.6.8 and, because it's distributed under LGPL, was
objectionable to many Nokogiri users ([#1488](https://github.com/sparklemotion/nokogiri/issues/1488), [#1496](https://github.com/sparklemotion/nokogiri/issues/1496)).

This version makes `pkg-config` an optional dependency. If it's
installed, it's used; but otherwise Nokogiri will attempt to work
around its absence.


## 1.6.8 / 2016-06-06

### Security

[MRI] Bundled libxml2 is upgraded to 2.9.4, which fixes many security issues. Many of these had previously been patched in the vendored libxml 2.9.2 in the 1.6.7.x branch, but some are newer.

See these libxml2 email posts for more:

* https://mail.gnome.org/archives/xml/2015-November/msg00012.html
* https://mail.gnome.org/archives/xml/2016-May/msg00023.html

For a more detailed analysis, you may care to read Canonical's take on these security issues:

* http://www.ubuntu.com/usn/usn-2994-1


[MRI] Bundled libxslt is upgraded to 1.1.29, which fixes a security issue as well as many long-known outstanding bugs, some features, some portability improvements, and general cleanup.

See this libxslt email post for more:

* https://mail.gnome.org/archives/xslt/2016-May/msg00004.html


### Added

Several changes were made to improve performance:

* [MRI] Simplify `NodeSet#to_a` with a minor speed-up. ([#1397](https://github.com/sparklemotion/nokogiri/issues/1397))
* `XML::Node#ancestors` optimization. ([#1297](https://github.com/sparklemotion/nokogiri/issues/1297)) (Thanks, Bruno Sutic!)
* Use `Symbol#to_proc` where we weren't previously. ([#1296](https://github.com/sparklemotion/nokogiri/issues/1296)) (Thanks, Bruno Sutic!)
* `XML::DTD#each` uses implicit block calls. (Thanks, [@glaucocustodio](https://github.com/glaucocustodio)!)
* Fall back to the `pkg-config` gem if we're having trouble finding the system libxml2. This should help many FreeBSD users. ([#1417](https://github.com/sparklemotion/nokogiri/issues/1417))
* Set document encoding appropriately even on blank document. ([#1043](https://github.com/sparklemotion/nokogiri/issues/1043)) (Thanks, [@batter](https://github.com/batter)!)


### Fixed

* [JRuby] fix slow add_child ([#692](https://github.com/sparklemotion/nokogiri/issues/692))
* [JRuby] fix load errors when deploying to JRuby/Torquebox ([#1114](https://github.com/sparklemotion/nokogiri/issues/1114)) (Thanks, [@atambo](https://github.com/atambo) and [@jvshahid](https://github.com/jvshahid)!)
* [JRuby] fix NPE when inspecting nodes returned by `NodeSet#drop` ([#1042](https://github.com/sparklemotion/nokogiri/issues/1042)) (Thanks, [@mkristian](https://github.com/mkristian)!)
* [JRuby] fix nil attriubte node's namespace in reader ([#1327](https://github.com/sparklemotion/nokogiri/issues/1327)) (Thanks, [@codekitchen](https://github.com/codekitchen)!)
* [JRuby] fix Nokogiri munging unicode characters that require more than 2 bytes ([#1113](https://github.com/sparklemotion/nokogiri/issues/1113)) (Thanks, [@mkristian](https://github.com/mkristian)!)
* [JRuby] allow unlinking an unparented node ([#1112](https://github.com/sparklemotion/nokogiri/issues/1112), [#1152](https://github.com/sparklemotion/nokogiri/issues/1152)) (Thanks, [@esse](https://github.com/esse)!)
* [JRuby] allow Fragment parsing on a frozen string ([#444](https://github.com/sparklemotion/nokogiri/issues/444), [#1077](https://github.com/sparklemotion/nokogiri/issues/1077))
* [JRuby] HTML `style` tags are no longer encoded ([#1316](https://github.com/sparklemotion/nokogiri/issues/1316)) (Thanks, [@tbeauvais](https://github.com/tbeauvais)!)
* [MRI] fix assertion failure while accessing attribute node's namespace in reader ([#843](https://github.com/sparklemotion/nokogiri/issues/843)) (Thanks, [@2potatocakes](https://github.com/2potatocakes)!)
* [MRI] fix issue with GCing namespace nodes returned in an xpath query. ([#1155](https://github.com/sparklemotion/nokogiri/issues/1155))
* [MRI] Ensure C strings are null-terminated. ([#1381](https://github.com/sparklemotion/nokogiri/issues/1381))
* [MRI] Ensure Rubygems is loaded before using mini_portile2 at installation. ([#1393](https://github.com/sparklemotion/nokogiri/issues/1393), [#1411](https://github.com/sparklemotion/nokogiri/issues/1411)) (Thanks, [@JonRowe](https://github.com/JonRowe)!)
* [MRI] Handling another edge case where the `libxml-ruby` gem's global callbacks were smashing the heap. ([#1426](https://github.com/sparklemotion/nokogiri/issues/1426)). (Thanks to [@bbergstrom](https://github.com/bbergstrom) for providing an isolated test case!)
* [MRI] Ensure encodings are passed to `Sax::Parser` xmldecl callback. ([#844](https://github.com/sparklemotion/nokogiri/issues/844))
* [MRI] Ensure default ns prefix is applied correctly when reparenting nodes to another document. ([#391](https://github.com/sparklemotion/nokogiri/issues/391)) (Thanks, [@ylecuyer](https://github.com/ylecuyer)!)
* [MRI] Ensure Reader handles non-existent attributes as expected. ([#1254](https://github.com/sparklemotion/nokogiri/issues/1254)) (Thanks, [@ccutrer](https://github.com/ccutrer)!)
* [MRI] Cleanup around namespace handling when reparenting nodes. ([#1332](https://github.com/sparklemotion/nokogiri/issues/1332), [#1333](https://github.com/sparklemotion/nokogiri/issues/1333), [#1444](https://github.com/sparklemotion/nokogiri/issues/1444)) (Thanks, [@cuttrer](https://github.com/cuttrer) and [@bradleybeddoes](https://github.com/bradleybeddoes)!)
* unescape special characters in CSS queries ([#1303](https://github.com/sparklemotion/nokogiri/issues/1303)) (Thanks, [@twalpole](https://github.com/twalpole)!)
* consistently handle empty documents ([#1349](https://github.com/sparklemotion/nokogiri/issues/1349))
* Update to mini_portile2 2.1.0 to address whitespace-handling during patching. ([#1402](https://github.com/sparklemotion/nokogiri/issues/1402))
* Fix encoding of xml node namespaces.
* Work around issue installing Nokogiri on overlayfs (commonly used in Docker containers). ([#1370](https://github.com/sparklemotion/nokogiri/issues/1370), [#1405](https://github.com/sparklemotion/nokogiri/issues/1405))



### Notes

* Removed legacy code remaining from Ruby 1.8.x support.
* Removed legacy code remaining from REE support.
* Removing hacky workarounds for bugs in some older versions of libxml2.
* Handling C strings in a forward-compatible manner, see https://github.com/ruby/ruby/blob/v2_2_0/NEWS#L319


## 1.6.7.2 / 2016-01-20

This version pulls in several upstream patches to the vendored libxml2 and libxslt to address:

* CVE-2015-7499

Ubuntu classifies this as "Priority: Low", RedHat classifies this as "Impact: Moderate", and NIST classifies this as "Severity: 5.0 (MEDIUM)".

MITRE record is https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-7499


## 1.6.7.1 / 2015-12-16

This version pulls in several upstream patches to the vendored libxml2 and libxslt to address:

* CVE-2015-5312
* CVE-2015-7497
* CVE-2015-7498
* CVE-2015-7499
* CVE-2015-7500
* CVE-2015-8241
* CVE-2015-8242
* CVE-2015-8317

See also http://www.ubuntu.com/usn/usn-2834-1/


## 1.6.7 / 2015-11-29

### Added

This version supports native builds on Windows using the RubyInstaller
DevKit. It also supports Ruby 2.2.x on Windows, as well as making
several other improvements to the installation process on various
platforms.

### Security

This version also includes the security patches already applied in
v1.6.6.3 and v1.6.6.4 to the vendored libxml2 and libxslt source.
See [#1374](https://github.com/sparklemotion/nokogiri/issues/1374) and [#1376](https://github.com/sparklemotion/nokogiri/issues/1376) for details.

### Added

* Cross-built gems now have a proper ruby version requirement. ([#1266](https://github.com/sparklemotion/nokogiri/issues/1266))
* Ruby 2.2.x is supported on Windows.
* Native build is supported on Windows.
* [MRI] libxml2 and libxslt `config.guess` files brought up to date. ([#1326](https://github.com/sparklemotion/nokogiri/issues/1326)) (Thanks, [[@hernan](https://github.com/hernan)-erasmo](https://github.com/hernan-erasmo)!)
* [JRuby] fix error in validating files with jruby ([#1355](https://github.com/sparklemotion/nokogiri/issues/1355), [#1361](https://github.com/sparklemotion/nokogiri/issues/1361)) (Thanks, [@twalpole](https://github.com/twalpole)!)
* [MRI, OSX] Patch to handle nonstandard location of `iconv.h`. ([#1206](https://github.com/sparklemotion/nokogiri/issues/1206), [#1210](https://github.com/sparklemotion/nokogiri/issues/1210), [#1218](https://github.com/sparklemotion/nokogiri/issues/1218), [#1345](https://github.com/sparklemotion/nokogiri/issues/1345)) (Thanks, [@neonichu](https://github.com/neonichu)!)

### Fixed

* [JRuby] reset the namespace cache when replacing the document's innerHtml ([#1265](https://github.com/sparklemotion/nokogiri/issues/1265)) (Thanks, [@mkristian](https://github.com/mkristian)!)
* [JRuby] `Document#parse` should support IO objects that respond to `#read`. ([#1124](https://github.com/sparklemotion/nokogiri/issues/1124)) (Thanks, Jake Byman!)
* [MRI] Duplicate-id errors when setting the `id` attribute on HTML documents are now silenced. ([#1262](https://github.com/sparklemotion/nokogiri/issues/1262))
* [JRuby] SAX parser cuts texts in pieces when square brackets exist. ([#1261](https://github.com/sparklemotion/nokogiri/issues/1261))
* [JRuby] Namespaced attributes aren't removed by remove_attribute. ([#1299](https://github.com/sparklemotion/nokogiri/issues/1299))


## 1.6.6.4 / 2015-11-19

This version pulls in an upstream patch to the vendored libxml2 to address:

* unclosed comment uninitialized access issue ([#1376](https://github.com/sparklemotion/nokogiri/issues/1376))

This issue was assigned CVE-2015-8710 after the fact. See http://seclists.org/oss-sec/2015/q4/616 for details.


## 1.6.6.3 / 2015-11-16

This version pulls in several upstream patches to the vendored libxml2 and libxslt to address:

* CVE-2015-1819
* CVE-2015-7941_1
* CVE-2015-7941_2
* CVE-2015-7942
* CVE-2015-7942-2
* CVE-2015-8035
* CVE-2015-7995

See [#1374](https://github.com/sparklemotion/nokogiri/issues/1374) for details.


## 1.6.6.2 / 2015-01-23

### Fixed

* Fixed installation issue affecting compiler arguments. ([#1230](https://github.com/sparklemotion/nokogiri/issues/1230))


## 1.6.6.1 / 2015-01-22

Note that 1.6.6.0 was not released.


### Added

* Unified `Node` and `NodeSet` implementations of `#search`, `#xpath` and `#css`.
* Added `Node#lang` and `Node#lang=`.
* `bin/nokogiri` passes the URI to `parse()` if an HTTP URL is given.
* `bin/nokogiri` now loads `~/.nokogirirc` so user can define helper methods, etc.
* `bin/nokogiri` can be configured to use Pry instead of IRB by adding a couple of lines to ~/.nokogirirc. ([#1198](https://github.com/sparklemotion/nokogiri/issues/1198))
* `bin/nokogiri` can better handle urls from STDIN (aiding use of xargs). ([#1065](https://github.com/sparklemotion/nokogiri/issues/1065))
* JRuby 9K support.


### Fixed

* `DocumentFragment#search` now matches against root nodes. ([#1205](https://github.com/sparklemotion/nokogiri/issues/1205))
* (MRI) More fixes related to handling libxml2 parse errors during `DocumentFragment#dup`. ([#1196](https://github.com/sparklemotion/nokogiri/issues/1196))
* (JRuby) Builder now handles namespace hrefs properly when there is a default ns. ([#1039](https://github.com/sparklemotion/nokogiri/issues/1039))
* (JRuby) Clear the XPath cache on attr removal. ([#1109](https://github.com/sparklemotion/nokogiri/issues/1109))
* `XML::Comment.new` argument types are now consistent and safe (and documented) across MRI and JRuby. ([#1224](https://github.com/sparklemotion/nokogiri/issues/1224))
* (MRI) Restoring support for Ruby 1.9.2 that was broken in v1.6.4.1 and v1.6.5. ([#1207](https://github.com/sparklemotion/nokogiri/issues/1207))
* Check if `zlib` is available before building `libxml2`. ([#1188](https://github.com/sparklemotion/nokogiri/issues/1188))
* (JRuby) HtmlSaxPushParser now exists. ([#1147](https://github.com/sparklemotion/nokogiri/issues/1147)) (Thanks, Piotr Szmielew!)


## 1.6.5 / 2014-11-26

### Added

* Implement `Slop#respond_to_missing?`. ([#1176](https://github.com/sparklemotion/nokogiri/issues/1176))
* Optimized the XPath query generated by an `an+b` CSS query.


### Fixed

* Capture non-parse errors from `Document#dup` in `Document#errors`. ([#1196](https://github.com/sparklemotion/nokogiri/issues/1196))
* (JRuby) `Document#canonicalize` parameters are now consistent with MRI. ([#1189](https://github.com/sparklemotion/nokogiri/issues/1189))


## 1.6.4.1 / 2014-11-05

### Fixed

* (MRI) Fix a bug where CFLAGS passed in are dropped. ([#1188](https://github.com/sparklemotion/nokogiri/issues/1188))
* Fix a bug where CSS selector :nth(n) did not work. ([#1187](https://github.com/sparklemotion/nokogiri/issues/1187))


## 1.6.4 / 2014-11-04

### Added

* (MRI) Bundled Libxml2 is upgraded to 2.9.2.
* (MRI) `nokogiri --version` will include a list of applied patches.
* (MRI) Nokogiri no longer prints messages directly to TTY while building the extension.
* (MRI) Detect and help user fix a missing /usr/include/iconv.h on OS X. ([#1111](https://github.com/sparklemotion/nokogiri/issues/1111))
* (MRI) Improve the iconv detection for building libxml2.

### Fixed

* (MRI) Fix `DocumentFragment#element_children` ([#1138](https://github.com/sparklemotion/nokogiri/issues/1138)).
* Fix a bug with CSS attribute selector without any prefix where "foo [bar]" was treated as "foo[bar]". ([#1174](https://github.com/sparklemotion/nokogiri/issues/1174))


## 1.6.3.1 / 2014-07-21

### Fixed

* Addressing an Apple Macintosh installation problem for GCC users. [#1130](https://github.com/sparklemotion/nokogiri/issues/1130) (Thanks, [@zenspider](https://github.com/zenspider)!)


## 1.6.3 / 2014-07-20

### Added

* Added `Node#document?` and `Node#processing_instruction?`


### Fixed

* [JRuby] Fix Ruby memory exhaustion vulnerability. [#1087](https://github.com/sparklemotion/nokogiri/issues/1087) (Thanks, [@ocher](https://github.com/ocher))
* [MRI] Fix segfault during GC when using `libxml-ruby` and `nokogiri` together in multi-threaded environment. [#895](https://github.com/sparklemotion/nokogiri/issues/895) (Thanks, [@ender672](https://github.com/ender672)!)
* Building on OSX 10.9 stock ruby 2.0.0 now works. [#1101](https://github.com/sparklemotion/nokogiri/issues/1101) (Thanks, [@zenspider](https://github.com/zenspider)!)
* `Node#parse` now works again for HTML document nodes (broken in 1.6.2+).
* Processing instructions can now be added via `Node#add_next_sibling`.


## 1.6.2.1 / 2014-05-13

### Fixed

* Fix statically-linked libxml2 installation when using universal builds of Ruby. [#1104](https://github.com/sparklemotion/nokogiri/issues/1104)
* Patching `mini_portile` to address the git dependency detailed in [#1102](https://github.com/sparklemotion/nokogiri/issues/1102).
* Library load fix to address segfault reported on some systems. [#1097](https://github.com/sparklemotion/nokogiri/issues/1097)


## 1.6.2 / 2014-05-12

### Security

A set of security and bugfix patches have been backported from the libxml2 and libxslt repositories onto the version of 2.8.0 packaged with Nokogiri, including these notable security fixes:

* https://git.gnome.org/browse/libxml2/commit/?id=4629ee02ac649c27f9c0cf98ba017c6b5526070f
* CVE-2013-2877 https://git.gnome.org/browse/libxml2/commit/?id=e50ba8164eee06461c73cd8abb9b46aa0be81869
* CVE-2014-0191 https://git.gnome.org/browse/libxml2/commit/?id=9cd1c3cfbd32655d60572c0a413e017260c854df

It is recommended that you upgrade from 1.6.x to this version as soon as possible.

### Dependencies

Now requires libxml >= 2.6.21 (was previously >= 2.6.17).

### Added

* Add cross building of fat binary gems for 64-Bit Windows (x64-mingw32) and add support for native builds on Windows. [#864](https://github.com/sparklemotion/nokogiri/issues/864), [#989](https://github.com/sparklemotion/nokogiri/issues/989), [#1072](https://github.com/sparklemotion/nokogiri/issues/1072)
* (MRI) Alias CP932 to Windows-31J if iconv does not support Windows-31J.
* (MRI) Nokogiri now links packaged libraries statically. To disable static linking, pass --disable-static to `extconf.rb`. [#923](https://github.com/sparklemotion/nokogiri/issues/923)
* (MRI) Fix a library path (LIBPATH) precedence problem caused by CRuby bug [#9760](https://github.com/sparklemotion/nokogiri/issues/9760).
* (MRI) Nokogiri automatically deletes directories of packaged libraries only used during build. To keep them for debugging purposes, pass --disable-clean to `extconf.rb`. [#952](https://github.com/sparklemotion/nokogiri/issues/952)
* (MRI) Nokogiri now builds libxml2 properly with iconv support on platforms where libiconv is installed outside the system default directories, such as FreeBSD.
* Add support for an-b in nth selectors. [#886](https://github.com/sparklemotion/nokogiri/issues/886) (Thanks, Magnus Bergmark!)
* Add support for bare and multiple `:not()` functions in selectors. [#887](https://github.com/sparklemotion/nokogiri/issues/887) (Thanks, Magnus Bergmark!)
* (MRI) Add an `extconf.rb` option --use-system-libraries, alternative to setting the environment variable NOKOGIRI_USE_SYSTEM_LIBRARIES.
* (MRI) Update packaged libraries: libxslt to 1.1.28, zlib to 1.2.8, and libiconv to 1.14, respectively.
* `Nokogiri::HTML::Document#title=` and `#meta_encoding`= now always add an element if not present, trying hard to find the best place to put it.
* `Nokogiri::XML::DTD#html_dtd?` and `#html5_dtd?` are added.
* `Nokogiri::XML::Node#prepend_child` is added. [#664](https://github.com/sparklemotion/nokogiri/issues/664)
* `Nokogiri::XML::SAX::ParserContext#recovery` is added. [#453](https://github.com/sparklemotion/nokogiri/issues/453)
* Fix documentation for `XML::Node#namespace`. [#803](https://github.com/sparklemotion/nokogiri/issues/803) [#802](https://github.com/sparklemotion/nokogiri/issues/802) (Thanks, Hoylen Sue)
* Allow `Nokogiri::XML::Node#parse` from unparented non-element nodes. [#407](https://github.com/sparklemotion/nokogiri/issues/407)

### Fixed

* Ensure :only-child pseudo class works within :not pseudo class. [#858](https://github.com/sparklemotion/nokogiri/issues/858) (Thanks, Yamagishi Kazutoshi!)
* Don't call pkg_config when using bundled libraries in `extconf.rb` [#931](https://github.com/sparklemotion/nokogiri/issues/931) (Thanks, Shota Fukumori!)
* `Nokogiri.parse()` does not mistake a non-HTML document like a RSS document as HTML document. [#932](https://github.com/sparklemotion/nokogiri/issues/932) (Thanks, Yamagishi Kazutoshi!)
* (MRI) Perform a node type check before adding a child node to another. Previously adding a text node to another as a child could cause a SEGV. [#1092](https://github.com/sparklemotion/nokogiri/issues/1092)
* (JRuby) XSD validation crashes in Java version. [#373](https://github.com/sparklemotion/nokogiri/issues/373)
* (JRuby) Document already has a root node error while using Builder. [#646](https://github.com/sparklemotion/nokogiri/issues/646)
* (JRuby) c14n tests are all passing on JRuby. [#226](https://github.com/sparklemotion/nokogiri/issues/226)
* Parsing empty documents raise `SyntaxError` in strict mode. [#1005](https://github.com/sparklemotion/nokogiri/issues/1005)
* (JRuby) Make xpath faster by caching the xpath context. [#741](https://github.com/sparklemotion/nokogiri/issues/741)
* (JRuby) XML SAX push parser leaks memory on JRuby, but not on MRI. [#998](https://github.com/sparklemotion/nokogiri/issues/998)
* (JRuby) Inconsistent behavior aliasing the default namespace. [#940](https://github.com/sparklemotion/nokogiri/issues/940)
* (JRuby) Inconsistent behavior between parsing and adding namespaces. [#943](https://github.com/sparklemotion/nokogiri/issues/943)
* (JRuby) Xpath returns inconsistent result set on cloned document with namespaces and attributes. [#1034](https://github.com/sparklemotion/nokogiri/issues/1034)
* (JRuby) Java-Implementation forgets element namespaces [#902](https://github.com/sparklemotion/nokogiri/issues/902)
* (JRuby) JRuby-Nokogiri does not recognise attributes inside namespaces [#1081](https://github.com/sparklemotion/nokogiri/issues/1081)
* (JRuby) JRuby-Nokogiri has different comment node name [#1080](https://github.com/sparklemotion/nokogiri/issues/1080)
* (JRuby) JAXPExtensionsProvider / Java 7 / Secure Processing [#1070](https://github.com/sparklemotion/nokogiri/issues/1070)

## 1.6.1 / 2013-12-14

### Fixed

* (JRuby) Fix out of memory bug when certain invalid documents are parsed.
* (JRuby) Fix regression of billion-laughs vulnerability. [#586](https://github.com/sparklemotion/nokogiri/issues/586)


## 1.6.0 / 2013-06-08

This release was based on v1.5.10 and 1.6.0.rc1, and contains changes
mentioned in both.

### Deprecations

* Remove pre 1.9 monitoring from Travis.


## 1.6.0.rc1 / 2013-04-14

This release was based on v1.5.9, and so does not contain any fixes
mentioned in the notes for v1.5.10.

### Notes

* mini_portile is now a runtime dependency
* Ruby 1.9.2 and higher now required


### Added

* (MRI) Source code for libxml 2.8.0 and libxslt 1.2.26 is packaged with the gem. These libraries are compiled at gem install time unless the environment variable NOKOGIRI_USE_SYSTEM_LIBRARIES is set. VERSION_INFO (also `nokogiri -v`) exposes whether libxml was compiled from packaged source, or the system library was used.
* (Windows) libxml upgraded to 2.8.0


### Dependencies

* Support for Ruby 1.8.7 and prior has been dropped


## 1.5.11 / 2013-12-14

### Fixed

* (JRuby) Fix out of memory bug when certain invalid documents are parsed.
* (JRuby) Fix regression of billion-laughs vulnerability. [#586](https://github.com/sparklemotion/nokogiri/issues/586)


## 1.5.10 / 2013-06-07

### Fixed

* (JRuby) Fix "null document" error when parsing an empty IO in jruby 1.7.3. [#883](https://github.com/sparklemotion/nokogiri/issues/883)
* (JRuby) Fix schema validation when XSD has DOCTYPE set to DTD. [#912](https://github.com/sparklemotion/nokogiri/issues/912) (Thanks, Patrick Cheng!)
* (MRI) Fix segfault when there is no default subelement for an HTML node. [#917](https://github.com/sparklemotion/nokogiri/issues/917)


### Notes

* Use rb_ary_entry instead of RARRAY_PTR (you know, for Rubinius). [#877](https://github.com/sparklemotion/nokogiri/issues/877) (Thanks, Dirkjan Bussink!)
* Fix TypeError when running tests. [#900](https://github.com/sparklemotion/nokogiri/issues/900) (Thanks, Cédric Boutillier!)


## 1.5.9 / 2013-03-21

### Fixed

* Ensure that prefixed attributes are properly namespaced when reparented. [#869](https://github.com/sparklemotion/nokogiri/issues/869)
* Fix for inconsistent namespaced attribute access for SVG nested in HTML. [#861](https://github.com/sparklemotion/nokogiri/issues/861)
* (MRI) Fixed a memory leak in fragment parsing if nodes are not all subsequently reparented. [#856](https://github.com/sparklemotion/nokogiri/issues/856)


## 1.5.8 / 2013-03-19

### Fixed

* (JRuby) Fix EmptyStackException thrown by elements with xlink:href attributes and no base_uri [#534](https://github.com/sparklemotion/nokogiri/issues/534), [#805](https://github.com/sparklemotion/nokogiri/issues/805). (Thanks, Patrick Quinn and Brian Hoffman!)
* Fixes duplicate attributes issue introduced in 1.5.7. [#865](https://github.com/sparklemotion/nokogiri/issues/865)
* Allow use of a prefixed namespace on a root node using `Nokogiri::XML::Builder` [#868](https://github.com/sparklemotion/nokogiri/issues/868)


## 1.5.7 / 2013-03-18

### Added

* Windows support for Ruby 2.0.


### Fixed

* `SAX::Parser.parse_io` throw an error when used with lower case encoding. [#828](https://github.com/sparklemotion/nokogiri/issues/828)
* (JRuby) Java Nokogiri is finally green (passes all tests) under 1.8 and 1.9 mode. High five everyone. [#798](https://github.com/sparklemotion/nokogiri/issues/798), [#705](https://github.com/sparklemotion/nokogiri/issues/705)
* (JRuby) `Nokogiri::XML::Reader` broken (as a pull parser) on jruby - reads the whole XML document. [#831](https://github.com/sparklemotion/nokogiri/issues/831)
* (JRuby) JRuby hangs parsing "&amp;". [#837](https://github.com/sparklemotion/nokogiri/issues/837)
* (JRuby) JRuby NPE parsing an invalid XML instruction. [#838](https://github.com/sparklemotion/nokogiri/issues/838)
* (JRuby) `Node#content=` incompatibility. [#839](https://github.com/sparklemotion/nokogiri/issues/839)
* (JRuby) to_xhtml doesn't print the last slash for self-closing tags in JRuby. [#834](https://github.com/sparklemotion/nokogiri/issues/834)
* (JRuby) Adding an `EntityReference` after a Text node mangles the entity in JRuby. [#835](https://github.com/sparklemotion/nokogiri/issues/835)
* (JRuby) JRuby version inconsistency: nil for empty attributes. [#818](https://github.com/sparklemotion/nokogiri/issues/818)
* CSS queries for classes (e.g., ".foo") now treat all whitespace identically. [#854](https://github.com/sparklemotion/nokogiri/issues/854)
* Namespace behavior cleaned up and made consistent between JRuby and MRI. [#846](https://github.com/sparklemotion/nokogiri/issues/846), [#801](https://github.com/sparklemotion/nokogiri/issues/801) (Thanks, Michael Klein!)
* (MRI) SAX parser handles empty processing instructions. [#845](https://github.com/sparklemotion/nokogiri/issues/845)


## 1.5.6 / 2012-12-19

### Added

* Improved performance of `XML::Document#collect_namespaces`. [#761](https://github.com/sparklemotion/nokogiri/issues/761) (Thanks, Juergen Mangler!)
* New callback `SAX::Document#processing_instruction` (Thanks, Kitaiti Makoto!)
* `Node#native_content=` allows setting unescaped node content. [#768](https://github.com/sparklemotion/nokogiri/issues/768)
* XPath lookup with namespaces supports symbol keys. [#729](https://github.com/sparklemotion/nokogiri/issues/729) (Thanks, Ben Langfeld.)
* `XML::Node#[]=` stringifies values. [#729](https://github.com/sparklemotion/nokogiri/issues/729) (Thanks, Ben Langfeld.)
* `bin/nokogiri` will process a document from $stdin
* `bin/nokogiri -e` will execute a program from the command line
* (JRuby) `bin/nokogiri --version` will print the Xerces and NekoHTML versions.


### Fixed

* Nokogiri now detects XSLT transform errors. [#731](https://github.com/sparklemotion/nokogiri/issues/731) (Thanks, Justin Fitzsimmons!)
* Don't throw an Error when trying to replace top-level text node in DocumentFragment. [#775](https://github.com/sparklemotion/nokogiri/issues/775)
* Raise an ArgumentError if an invalid encoding is passed to the SAX parser. [#756](https://github.com/sparklemotion/nokogiri/issues/756) (Thanks, Bradley Schaefer!)
* Prefixed element inconsistency between CRuby and JRuby. [#712](https://github.com/sparklemotion/nokogiri/issues/712)
* (JRuby) space prior to xml preamble causes nokogiri to fail parsing. (fixed along with [#748](https://github.com/sparklemotion/nokogiri/issues/748)) [#790](https://github.com/sparklemotion/nokogiri/issues/790)
* (JRuby) Fixed the bug `Nokogiri::XML::Node#content` inconsistency between Java and C. [#794](https://github.com/sparklemotion/nokogiri/issues/794), [#797](https://github.com/sparklemotion/nokogiri/issues/797)
* (JRuby) raises INVALID_CHARACTER_ERR exception when EntityReference name starts with '#'. [#719](https://github.com/sparklemotion/nokogiri/issues/719)
* (JRuby) doesn't coerce namespaces out of strings on a direct subclass of Node. [#715](https://github.com/sparklemotion/nokogiri/issues/715)
* (JRuby) `Node#content` now renders newlines properly. [#737](https://github.com/sparklemotion/nokogiri/issues/737) (Thanks, Piotr Szmielew!)
* (JRuby) Unknown namespace are ignore when the recover option is used. [#748](https://github.com/sparklemotion/nokogiri/issues/748)
* (JRuby) XPath queries for namespaces should not throw exceptions when called twice in a row. [#764](https://github.com/sparklemotion/nokogiri/issues/764)
* (JRuby) More consistent (with libxml2) whitespace formatting when emitting XML. [#771](https://github.com/sparklemotion/nokogiri/issues/771)
* (JRuby) namespaced attributes broken when appending raw xml to builder. [#770](https://github.com/sparklemotion/nokogiri/issues/770)
* (JRuby) `Nokogiri::XML::Document#wrap` raises undefined method `length' for nil:NilClass when trying to << to a node. [#781](https://github.com/sparklemotion/nokogiri/issues/781)
* (JRuby) Fixed "bad file descriptor" bug when closing open file descriptors. [#495](https://github.com/sparklemotion/nokogiri/issues/495)
* (JRuby) JRuby/CRuby incompatibility for attribute decorators. [#785](https://github.com/sparklemotion/nokogiri/issues/785)
* (JRuby) Issues parsing valid XML with no internal subset in the DTD. [#547](https://github.com/sparklemotion/nokogiri/issues/547), [#811](https://github.com/sparklemotion/nokogiri/issues/811)
* (JRuby) Issues parsing valid node content when it contains colons. [#728](https://github.com/sparklemotion/nokogiri/issues/728)
* (JRuby) Correctly parse the doc type of html documents. [#733](https://github.com/sparklemotion/nokogiri/issues/733)
* (JRuby) Include dtd in the xml output when a builder is used with create_internal_subset. [#751](https://github.com/sparklemotion/nokogiri/issues/751)
* (JRuby) builder requires textwrappers for valid utf8 in jruby, not in mri. [#784](https://github.com/sparklemotion/nokogiri/issues/784)


## 1.5.5 / 2012-06-24

### Added

* Much-improved support for JRuby in 1.9 mode! Yay!

### Fixed

* Regression in JRuby Nokogiri add_previous_sibling (1.5.0 -> 1.5.1) [#691](https://github.com/sparklemotion/nokogiri/issues/691) (Thanks, John Shahid!)
* JRuby unable to create HTML doc if URL arg provided [#674](https://github.com/sparklemotion/nokogiri/issues/674) (Thanks, John Shahid!)
* JRuby raises NullPointerException when given HTML document is nil or empty string. [#699](https://github.com/sparklemotion/nokogiri/issues/699)
* JRuby 1.9 error, uncaught throw 'encoding_found', has been fixed. [#673](https://github.com/sparklemotion/nokogiri/issues/673)
* Invalid encoding returned in JRuby with US-ASCII. [#583](https://github.com/sparklemotion/nokogiri/issues/583)
* XmlSaxPushParser raises IndexOutOfBoundsException when over 512 characters are given. [#567](https://github.com/sparklemotion/nokogiri/issues/567), [#615](https://github.com/sparklemotion/nokogiri/issues/615)
* When xpath evaluation returns empty `NodeSet`, decorating `NodeSet`'s base document raises exception. [#514](https://github.com/sparklemotion/nokogiri/issues/514)
* JRuby raises exception when xpath with namespace is specified. pull request [#681](https://github.com/sparklemotion/nokogiri/issues/681) (Thanks, Piotr Szmielew)
* JRuby renders nodes without their namespace when subclassing Node. [#695](https://github.com/sparklemotion/nokogiri/issues/695)
* JRuby raises NAMESPACE_ERR (org.w3c.dom.DOMException) while instantiating `RDF::RDFXML::Writer`. [#683](https://github.com/sparklemotion/nokogiri/issues/683)
* JRuby is not able to use namespaces in xpath. [#493](https://github.com/sparklemotion/nokogiri/issues/493)
* JRuby's Entity resolving should be consistent with C-Nokogiri [#704](https://github.com/sparklemotion/nokogiri/issues/704), [#647](https://github.com/sparklemotion/nokogiri/issues/647), [#703](https://github.com/sparklemotion/nokogiri/issues/703)


## 1.5.4 / 2012-06-12

### Added

* The "nokogiri" script now has more verbose output when passed the `--rng` option. [#675](https://github.com/sparklemotion/nokogiri/issues/675) (Thanks, Dan Radez!)
* Build support on hardened Debian systems that use `-Werror=format-security`. [#680](https://github.com/sparklemotion/nokogiri/issues/680).
* Better build support for systems with pkg-config. [#584](https://github.com/sparklemotion/nokogiri/issues/584)
* Better build support for systems with multiple iconv installations.

### Fixed

* Segmentation fault when creating a comment node for a DocumentFragment. [#677](https://github.com/sparklemotion/nokogiri/issues/677), [#678](https://github.com/sparklemotion/nokogiri/issues/678).
* Treat '.' as xpath in `at()` and `search()`. [#690](https://github.com/sparklemotion/nokogiri/issues/690)

### Security

(MRI) Default parse options for XML documents were changed to not make network connections during document parsing, to avoid XXE vulnerability. [#693](https://github.com/sparklemotion/nokogiri/issues/693)

To re-enable this behavior, the configuration method `nononet` may be called, like this:

``` ruby
Nokogiri::XML::Document.parse(xml) { |config| config.nononet }
```

Insert your own joke about double-negatives here.


## 1.5.3 / 2012-06-01

### Added

* Support for "prefixless" CSS selectors ~, > and + like jQuery supports. [#621](https://github.com/sparklemotion/nokogiri/issues/621), [#623](https://github.com/sparklemotion/nokogiri/issues/623). (Thanks, David Lee!)
* Attempting to improve installation on homebrew 0.9 (with regards to iconv). Isn't package management convenient?

### Fixed

* Custom xpath functions with empty nodeset arguments cause a segfault. [#634](https://github.com/sparklemotion/nokogiri/issues/634).
* `Nokogiri::XML::Node#css` now works for XML documents with default namespaces when the rule contains attribute selector without namespace.
* Fixed marshalling bugs around how arguments are passed to (and returned from) XSLT custom xpath functions. [#640](https://github.com/sparklemotion/nokogiri/issues/640).
* `Nokogiri::XML::Reader#outer_xml` is broken in JRuby [#617](https://github.com/sparklemotion/nokogiri/issues/617)
* `Nokogiri::XML::Attribute` on JRuby returns a nil namespace [#647](https://github.com/sparklemotion/nokogiri/issues/647)
* `Nokogiri::XML::Node#namespace=` cannot set a namespace without a prefix on JRuby [#648](https://github.com/sparklemotion/nokogiri/issues/648)
* (JRuby) 1.9 mode causes dead lock while running rake [#571](https://github.com/sparklemotion/nokogiri/issues/571)
* `HTML::Document#meta_encoding` does not raise exception on docs with malformed content-type. [#655](https://github.com/sparklemotion/nokogiri/issues/655)
* Fixing segfault related to unsupported encodings in in-context parsing on 1.8.7. [#643](https://github.com/sparklemotion/nokogiri/issues/643)
* (JRuby) Concurrency issue in XPath parsing. [#682](https://github.com/sparklemotion/nokogiri/issues/682)


## 1.5.2 / 2012-03-09

Repackaging of 1.5.1 with a gemspec that is compatible with older Rubies. [#631](https://github.com/sparklemotion/nokogiri/issues/631), [#632](https://github.com/sparklemotion/nokogiri/issues/632).


## 1.5.1 / 2012-03-09

### Added

* `XML::Builder#comment` allows creation of comment nodes.
* CSS searches now support namespaced attributes. [#593](https://github.com/sparklemotion/nokogiri/issues/593)
* Java integration feature is added. Now, `XML::Document.wrap` and `XML::Document#to_java` methods are available.
* RelaxNG validator support in the `nokogiri` cli utility. [#591](https://github.com/sparklemotion/nokogiri/issues/591) (thanks, Dan Radez!)

### Fixed

* Fix many memory leaks and segfault opportunities. Thanks, Tim Elliott!
* extconf searches homebrew paths if homebrew is installed.
* Inconsistent behavior of Nokogiri 1.5.0 Java [#620](https://github.com/sparklemotion/nokogiri/issues/620)
* Inheriting from `Nokogiri::XML::Node` on JRuby (1.6.4/5) fails [#560](https://github.com/sparklemotion/nokogiri/issues/560)
* `XML::Attr` nodes are not allowed to be added as node children, so an exception is raised. [#558](https://github.com/sparklemotion/nokogiri/issues/558)
* No longer defensively "pickle" adjacent text nodes on `Node#add_next_sibling` and `Node#add_previous_sibling` calls. [#595](https://github.com/sparklemotion/nokogiri/issues/595).
* Java version inconsistency: it returns nil for empty attributes [#589](https://github.com/sparklemotion/nokogiri/issues/589)
* to_xhtml incorrectly generates `<p /></p>` when tag is empty [#557](https://github.com/sparklemotion/nokogiri/issues/557)
* `Document#add_child` now accepts a `Node`, `NodeSet`, `DocumentFragment`, or `String`. [#546](https://github.com/sparklemotion/nokogiri/issues/546).
* `Document#create_element` now recognizes namespaces containing non-word characters (like "SOAP-ENV"). This is mostly relevant to users of Builder, which calls `Document#create_element` for nearly everything. [#531](https://github.com/sparklemotion/nokogiri/issues/531).
* File encoding broken in 1.5.0 / jruby / windows [#529](https://github.com/sparklemotion/nokogiri/issues/529)
* Java version does not return namespace defs as attrs for `::HTML` [#542](https://github.com/sparklemotion/nokogiri/issues/542)
* Bad file descriptor with Nokogiri 1.5.0 [#495](https://github.com/sparklemotion/nokogiri/issues/495)
* remove_namespace! doesn't work in pure java version [#492](https://github.com/sparklemotion/nokogiri/issues/492)
* The Nokogiri Java native build throws a null pointer exception when ActiveSupport's .blank? method is called directly on a parsed object. [#489](https://github.com/sparklemotion/nokogiri/issues/489)
* 1.5.0 Not using correct character encoding [#488](https://github.com/sparklemotion/nokogiri/issues/488)
* Raw XML string in XML Builder broken on JRuby [#486](https://github.com/sparklemotion/nokogiri/issues/486)
* Nokogiri 1.5.0 XML generation broken on JRuby [#484](https://github.com/sparklemotion/nokogiri/issues/484)
* Do not allow multiple root nodes. [#550](https://github.com/sparklemotion/nokogiri/issues/550)
* Fixes for custom XPath functions. [#605](https://github.com/sparklemotion/nokogiri/issues/605), [#606](https://github.com/sparklemotion/nokogiri/issues/606) (thanks, Juan Wajnerman!)
* `Node#to_xml` does not override `:save_with` if it is provided. [#505](https://github.com/sparklemotion/nokogiri/issues/505)
* `Node#set` is a private method (JRuby). [#564](https://github.com/sparklemotion/nokogiri/issues/564) (thanks, Nick Sieger!)
* C14n cleanup and `Node#canonicalize` (thanks, Ivan Pirlik!) [#563](https://github.com/sparklemotion/nokogiri/issues/563)


## 1.5.0 / 2011-07-01

### Notes

* See changelog from 1.4.7

### Added

* extracted sets of `Node::SaveOptions` into `Node::SaveOptions::DEFAULT_{X,H,XH}TML` (refactor)

### Fixed

* default output of XML on JRuby is no longer formatted due to inconsistent whitespace handling. [#415](https://github.com/sparklemotion/nokogiri/issues/415)
* (JRuby) making empty `NodeSet`s with null `nodes` member safe to operate on. [#443](https://github.com/sparklemotion/nokogiri/issues/443)
* Fix a bug in advanced encoding detection that leads to partially duplicated document when parsing an HTML file with unknown encoding.
* Add support for `<meta charset="...">`.


## 1.5.0 beta3 / 2010-12-02

### Notes

* JRuby performance tuning
* See changelog from 1.4.4

### Fixed

* `Node#inner_text` no longer returns nil. (JRuby) [#264](https://github.com/sparklemotion/nokogiri/issues/264)


## 1.5.0 beta2 / 2010-07-30

### Notes

* See changelog from 1.4.3


## 1.5.0 beta1 / 2010-05-22

### Notes

* JRuby support is provided by a new pure-java backend.

### Dependencies

* Ruby 1.8.6 is deprecated. Nokogiri will install, but official support is ended.
* LibXML 2.6.16 and earlier are deprecated. Nokogiri will refuse to install.

### Removed

* FFI support is removed.


## 1.4.7 / 2011-07-01

### Fixed

* Fix a bug in advanced encoding detection that leads to partially duplicated document when parsing an HTML file with unknown encoding. Thanks, Timothy Elliott ([@ender672](https://github.com/ender672))! [#478](https://github.com/sparklemotion/nokogiri/issues/478)


## 1.4.6 / 2011-06-19

### Notes

* This version is functionally identical to 1.4.5.
* Ruby 1.8.6 support has been restored.


## 1.4.5 / 2011-05-19

### Added

* `Nokogiri::HTML::Document#title` accessor gets and sets the document title.
* extracted sets of `Node::SaveOptions` into `Node::SaveOptions::DEFAULT_{X,H,XH}TML` (refactor)
* Raise an exception if a string is passed to `Nokogiri::XML::Schema#validate`. [#406](https://github.com/sparklemotion/nokogiri/issues/406)

### Fixed

* `Node#serialize`-and-friends now accepts a `SaveOption` object as the, erm, save object.
* `Nokogiri::CSS::Parser` has-a `Nokogiri::CSS::Tokenizer`
* (JRUBY+FFI only) Weak references are now threadsafe. [#355](https://github.com/sparklemotion/nokogiri/issues/355)
* Make direct `start_element()` callback (currently used for `HTML::SAX::Parser`) pass attributes in assoc array, just as emulated `start_element()` callback does.  rel. [#356](https://github.com/sparklemotion/nokogiri/issues/356)
* `HTML::SAX::Parser` should call back a block given to `parse*()` if any, just as `XML::SAX::Parser` does.
* Add further encoding detection to HTML parser that libxml2 does not do.
* `Document#remove_namespaces!` now handles attributes with namespaces. [#396](https://github.com/sparklemotion/nokogiri/issues/396)
* `XSLT::Stylesheet#transform` no longer segfaults when handed a non-`XML::Document`. [#452](https://github.com/sparklemotion/nokogiri/issues/452)
* `XML::Reader` no longer segfaults when under GC pressure. [#439](https://github.com/sparklemotion/nokogiri/issues/439)


## 1.4.4 / 2010-11-15

### Added

* `XML::Node#children=` sets the node's inner html (much like #inner_html=), but returns the reparent node(s).
* XSLT supports function extensions. [#336](https://github.com/sparklemotion/nokogiri/issues/336)
* XPath bind parameter substitution. [#329](https://github.com/sparklemotion/nokogiri/issues/329)
* `XML::Reader` node type constants. [#369](https://github.com/sparklemotion/nokogiri/issues/369)
* SAX Parser context provides line and column information

### Fixed

* `XML::DTD#attributes` returns an empty hash instead of nil when there are no attributes.
* `XML::DTD#{keys,each}` now work as expected. [#324](https://github.com/sparklemotion/nokogiri/issues/324)
* `{XML,HTML}::DocumentFragment.{new,parse}` no longer strip leading and trailing whitespace. [#319](https://github.com/sparklemotion/nokogiri/issues/319)
* `XML::Node#{add_child,add_previous_sibling,add_next_sibling,replace}` return a `NodeSet` when passed a string.
* Unclosed tags parsed more robustly in fragments. [#315](https://github.com/sparklemotion/nokogiri/issues/315)
* `XML::Node#{replace,add_previous_sibling,add_next_sibling}` edge cases fixed related to libxml's text node merging. [#308](https://github.com/sparklemotion/nokogiri/issues/308)
* Fixed a segfault when GC occurs during xpath handler argument marshalling. [#345](https://github.com/sparklemotion/nokogiri/issues/345)
* Added hack to `Slop` decorator to work with previously defined methods. [#330](https://github.com/sparklemotion/nokogiri/issues/330)
* Fix a memory leak when duplicating child nodes. [#353](https://github.com/sparklemotion/nokogiri/issues/353)
* Fixed off-by-one bug with `nth-last-{child,of-type}` CSS selectors when NOT using `an+b` notation. [#354](https://github.com/sparklemotion/nokogiri/issues/354)
* Fixed passing of non-namespace attributes to `SAX::Document#start_element`. [#356](https://github.com/sparklemotion/nokogiri/issues/356)
* Workaround for libxml2 in-context parsing bug. [#362](https://github.com/sparklemotion/nokogiri/issues/362)
* Fixed `NodeSet#wrap` on nodes within a fragment. [#331](https://github.com/sparklemotion/nokogiri/issues/331)


## 1.4.3 / 2010-07-28

### Added

* `XML::Reader#empty_element?` returns true for empty elements. [#262](https://github.com/sparklemotion/nokogiri/issues/262)
* `Node#remove_namespaces!` now removes namespace *declarations* as well. [#294](https://github.com/sparklemotion/nokogiri/issues/294)
* `NodeSet#at_xpath`, `NodeSet#at_css` and `NodeSet#>` do what the corresponding methods of `Node` do.

### Fixed

* `XML::NodeSet#{include?,delete,push}` accept an `XML::Namespace`
* `XML::Document#parse` added for parsing in the context of a document
* `XML::DocumentFragment#inner_html=` works with contextual parsing! [#298](https://github.com/sparklemotion/nokogiri/issues/298), [#281](https://github.com/sparklemotion/nokogiri/issues/281)
* `lib/nokogiri/css/parser.y` Combined CSS functions + pseudo selectors fixed
* Reparenting text nodes is safe, even when the operation frees adjacent merged nodes. [#283](https://github.com/sparklemotion/nokogiri/issues/283)
* Fixed libxml2 versionitis issue with `xmlFirstElementChild` et al. [#303](https://github.com/sparklemotion/nokogiri/issues/303)
* `XML::Attr#add_namespace` now works as expected. [#252](https://github.com/sparklemotion/nokogiri/issues/252)
* `HTML::DocumentFragment` uses the string's encoding. [#305](https://github.com/sparklemotion/nokogiri/issues/305)
* Fix the CSS3 selector translation rule for the general sibling combinator (a.k.a. preceding selector) that incorrectly converted "E ~ F G" to "//F//G[preceding-sibling::E]".


## 1.4.2 / 2010-05-22

### Added

* `XML::Node#parse` will parse XML or HTML fragments with respect to the context node.
* `XML::Node#namespaces` returns all namespaces defined in the node and all ancestor nodes (previously did not return ancestors' namespace definitions).
* Added `Enumerable` to `XML::Node`
* `Nokogiri::XML::Schema#validate` now uses xmlSchemaValidateFile if a filename is passed, which is faster and more memory-efficient. GH [#219](https://github.com/sparklemotion/nokogiri/issues/219)
* `XML::Document#create_entity` will create new `EntityDecl` objects. GH [#174](https://github.com/sparklemotion/nokogiri/issues/174)
* JRuby FFI implementation no longer uses `ObjectSpace._id2ref`, instead using Charles Nutter's rocking Weakling gem.
* `Nokogiri::XML::Node#first_element_child` fetch the first child node that is an ELEMENT node.
* `Nokogiri::XML::Node#last_element_child` fetch the last child node that is an ELEMENT node.
* `Nokogiri::XML::Node#elements` fetch all children nodes that are ELEMENT nodes.
* `Nokogiri::XML::Node#add_child`, `#add_previous_sibling`, `#before`, `#add_next_sibling`, `#after`, `#inner_html`, `#swap` and `#replace` all now accept a `Node`, `DocumentFragment`, `NodeSet`, or a string containing markup.
* `Node#fragment?` indicates whether a node is a `DocumentFragment`.

### Fixed

* `XML::NodeSet` is now always decorated (if the document has decorators). GH [#198](https://github.com/sparklemotion/nokogiri/issues/198)
* `XML::NodeSet#slice` gracefully handles offset+length larger than the set length. GH [#200](https://github.com/sparklemotion/nokogiri/issues/200)
* `XML::Node#content=` safely unlinks previous content. GH [#203](https://github.com/sparklemotion/nokogiri/issues/203)
* `XML::Node#namespace=` takes nil as a parameter
* `XML::Node#xpath` returns things other than `NodeSet` objects. GH [#208](https://github.com/sparklemotion/nokogiri/issues/208)
* `XSLT::StyleSheet#transform` accepts hashes for parameters. GH [#223](https://github.com/sparklemotion/nokogiri/issues/223)
* Psuedo selectors inside `not()` work. GH [#205](https://github.com/sparklemotion/nokogiri/issues/205)
* `XML::Builder` doesn't break when nodes are unlinked. Thanks to vihai! GH [#228](https://github.com/sparklemotion/nokogiri/issues/228)
* Encoding can be forced on the SAX parser. Thanks Eugene Pimenov! GH [#204](https://github.com/sparklemotion/nokogiri/issues/204)
* `XML::DocumentFragment` uses `XML::Node#parse` to determine children.
* Fixed a memory leak in xml reader. Thanks sdor! GH [#244](https://github.com/sparklemotion/nokogiri/issues/244)
* `Node#replace` returns the new child node as claimed in the RDoc. Previously returned +self+.

### Notes

* The Windows gems now bundle DLLs for libxml 2.7.6 and libxslt 1.1.26. Prior to this release, libxml 2.7.3 and libxslt 1.1.24 were bundled.


## 1.4.1 / 2009-12-10

### Added

* Added `Nokogiri::LIBXML_ICONV_ENABLED`
* Alias `Node#[]` to `Node#attr`
* `XML::Node#next_element` added
* `XML::Node#>` added for searching a nodes immediate children
* `XML::NodeSet#reverse` added
* Added fragment support to `Node#add_child`, `Node#add_next_sibling`, `Node#add_previous_sibling`, and `Node#replace`.
* `XML::Node#previous_element` implemented
* Rubinius support
* Ths CSS selector engine now supports `:has()`
* `XML::NodeSet#filter()` was added
* `XML::Node.next=` and .previous= are aliases for add_next_sibling and add_previous_sibling. GH [#183](https://github.com/sparklemotion/nokogiri/issues/183)

### Fixed

* XML fragments with namespaces do not raise an exception (regression in 1.4.0)
* `Node#matches?` works in nodes contained by a `DocumentFragment`. GH [#158](https://github.com/sparklemotion/nokogiri/issues/158)
* `Document` should not define `add_namespace()` method. GH [#169](https://github.com/sparklemotion/nokogiri/issues/169)
* `XPath` queries returning namespace declarations do not segfault.
* `Node#replace` works with nodes from different documents. GH [#162](https://github.com/sparklemotion/nokogiri/issues/162)
* Adding `XML::Document#collect_namespaces`
* Fixed bugs in the SOAP4R adapter
* Fixed bug in `XML::Node#next_element` for certain edge cases
* Fixed load path issue with JRuby under Windows. GH [#160](https://github.com/sparklemotion/nokogiri/issues/160).
* `XSLT#apply_to` will honor the "output method". Thanks richardlehane!
* Fragments containing leading text nodes with newlines now parse properly. GH [#178](https://github.com/sparklemotion/nokogiri/issues/178).


## 1.4.0 / 2009-10-30

### Added

* `Node#at_xpath` returns the first element of the `NodeSet` matching the XPath expression.
* `Node#at_css` returns the first element of the `NodeSet` matching the CSS selector.
* `NodeSet#|` for unions GH [#119](https://github.com/sparklemotion/nokogiri/issues/119) (Thanks Serabe!)
* `NodeSet#inspect` makes prettier output
* `Node#inspect` implemented for more rubyish document inspecting
* Added `XML::DTD#external_id`
* Added `XML::DTD#system_id`
* Added `XML::ElementContent` for DTD Element content validity
* Better namespace declaration support in `Nokogiri::XML::Builder`
* Added `XML::Node#external_subset`
* Added `XML::Node#create_external_subset`
* Added `XML::Node#create_internal_subset`
* XML Builder can append raw strings (GH [#141](https://github.com/sparklemotion/nokogiri/issues/141), patch from dudleyf)
* `XML::SAX::ParserContext` added
* `XML::Document#remove_namespaces!` for the namespace-impaired

### Fixed

* returns nil when HTML documents do not declare a meta encoding tag. GH [#115](https://github.com/sparklemotion/nokogiri/issues/115)
* Uses `RbConfig::CONFIG['host_os']` to adjust `ENV['PATH']` GH [#113](https://github.com/sparklemotion/nokogiri/issues/113)
* `NodeSet#search` is more efficient GH [#119](https://github.com/sparklemotion/nokogiri/issues/119) (Thanks Serabe!)
* `NodeSet#xpath` handles custom xpath functions
* Fixing a SEGV when `XML::Reader` gets attributes for current node
* `Node#inner_html` takes the same arguments as `Node#to_html` GH [#117](https://github.com/sparklemotion/nokogiri/issues/117)
* `DocumentFragment#css` delegates to it's child nodes GH [#123](https://github.com/sparklemotion/nokogiri/issues/123)
* `NodeSet#[]` works with slices larger than `NodeSet#length` GH [#131](https://github.com/sparklemotion/nokogiri/issues/131)
* Reparented nodes maintain their namespace. GH [#134](https://github.com/sparklemotion/nokogiri/issues/134)
* Fixed SEGV when adding an `XML::Document` to `NodeSet`
* `XML::SyntaxError` can be duplicated. GH [#148](https://github.com/sparklemotion/nokogiri/issues/148)

### Removed

* Hpricot compatibility layer removed


## 1.3.3 / 2009-07-26

### Added

* `NodeSet#children` returns all children of all nodes

### Fixed

* Override libxml-ruby's global error handler
* `ParseOption#strict` fixed
* Fixed a segfault when sending an empty string to `Node#inner_html=` GH [#88](https://github.com/sparklemotion/nokogiri/issues/88)
* String encoding is now set to UTF-8 in Ruby 1.9
* Fixed a segfault when moving root nodes between documents. GH [#91](https://github.com/sparklemotion/nokogiri/issues/91)
* Fixed an O(n) penalty on node creation. GH [#101](https://github.com/sparklemotion/nokogiri/issues/101)
* Allowing XML documents to be output as HTML documents

### Deprecations

* Hpricot compatibility layer will be removed in 1.4.0


## 1.3.2 / 2009-06-22

### Added

* `Nokogiri::XML::DTD#validate` will validate your document

### Fixed

* `Nokogiri::XML::NodeSet#search` will search top level nodes. GH [#73](https://github.com/sparklemotion/nokogiri/issues/73)
* Removed namespace related methods from `Nokogiri::XML::Document`
* Fixed a segfault when a namespace was added twice
* Made nokogiri work with Snow Leopard GH [#79](https://github.com/sparklemotion/nokogiri/issues/79)
* Mailing list has moved to: http://groups.google.com/group/nokogiri-talk
* HTML fragments now correctly handle comments and CDATA blocks. GH [#78](https://github.com/sparklemotion/nokogiri/issues/78)
* `Nokogiri::XML::Document#clone` is now an alias of dup

### Deprecations

* `Nokogiri::XML::SAX::Document#start_element_ns` is deprecated, please switch to `Nokogiri::XML::SAX::Document#start_element_namespace`
* `Nokogiri::XML::SAX::Document#end_element_ns` is deprecated, please switch to `Nokogiri::XML::SAX::Document#end_element_namespace`


## 1.3.1 / 2009-06-07

### Fixed

* `extconf.rb` checks for optional RelaxNG and Schema functions
* Namespace nodes are added to the Document node cache


## 1.3.0 / 2009-05-30

### Added

* Builder changes scope based on block arity
* Builder supports methods ending in underscore similar to tagz
* `Nokogiri::XML::Node#<=>` compares nodes based on Document position
* `Nokogiri::XML::Node#matches?` returns true if Node can be found with given selector.
* `Nokogiri::XML::Node#ancestors` now returns an `Nokogiri::XML::NodeSet`
* `Nokogiri::XML::Node#ancestors` will match parents against optional selector
* `Nokogiri::HTML::Document#meta_encoding` for getting the meta encoding
* `Nokogiri::HTML::Document#meta_encoding=` for setting the meta encoding
* `Nokogiri::XML::Document#encoding=` to set the document encoding
* `Nokogiri::XML::Schema` for validating documents against XSD schema
* `Nokogiri::XML::RelaxNG` for validating documents against RelaxNG schema
* `Nokogiri::HTML::ElementDescription` for fetching HTML element descriptions
* `Nokogiri::XML::Node#description` to fetch the node description
* `Nokogiri::XML::Node#accept` implements Visitor pattern
* `bin/nokogiri` for easily examining documents (Thanks Yutaka HARA!)
* `Nokogiri::XML::NodeSet` now supports more Array and Enumerable operators: index, delete, slice, - (difference), + (concatenation), & (intersection), push, pop, shift, ==
* `Nokogiri.XML`, `Nokogiri.HTML` take blocks that receive `Nokogiri::XML::ParseOptions` objects
* `Nokogiri::XML::Node#namespace` returns a `Nokogiri::XML::Namespace`
* `Nokogiri::XML::Node#namespace=` for setting a node's namespace
* `Nokogiri::XML::DocumentFragment` and `Nokogiri::HTML::DocumentFragment` have a sensible API and a more robust implementation.
* JRuby 1.3.0 support via FFI.

### Fixed

* Fixed a problem with nil passed to CDATA constructor
* Fragment method deals with regular expression characters (Thanks Joel!) LH [#73](https://github.com/sparklemotion/nokogiri/issues/73)
* Fixing builder scope issues LH [#61](https://github.com/sparklemotion/nokogiri/issues/61), LH [#74](https://github.com/sparklemotion/nokogiri/issues/74), LH [#70](https://github.com/sparklemotion/nokogiri/issues/70)
* Fixed a problem when adding a child could remove the child namespace LH[#78](https://github.com/sparklemotion/nokogiri/issues/78)
* Fixed bug with unlinking a node then reparenting it. (GH[#22](https://github.com/sparklemotion/nokogiri/issues/22))
* Fixed failure to catch errors during XSLT parsing (GH[#32](https://github.com/sparklemotion/nokogiri/issues/32))
* Fixed a bug with attribute conditions in CSS selectors (GH[#36](https://github.com/sparklemotion/nokogiri/issues/36))
* Fixed intolerance of HTML attributes without values in `Node#{before/after/inner_html=}`. (GH[#35](https://github.com/sparklemotion/nokogiri/issues/35))


## 1.2.3 / 2009-03-22

### Fixed

* Fixing bug where a node is passed in to `Node#new`
* Namespace should be assigned on DocumentFragment creation. LH [#66](https://github.com/sparklemotion/nokogiri/issues/66)
* `Nokogiri::XML::NodeSet#dup` works GH [#10](https://github.com/sparklemotion/nokogiri/issues/10)
* `Nokogiri::HTML` returns an empty Document when given a blank string GH[#11](https://github.com/sparklemotion/nokogiri/issues/11)
* Adding a child will remove duplicate namespace declarations LH [#67](https://github.com/sparklemotion/nokogiri/issues/67)
* Builder methods take a hash as a second argument


## 1.2.2 / 2009-03-14

### Added

* Nokogiri may be used with soap4r. See `XSD::XMLParser::Nokogiri`
* `Nokogiri::XML::Node#inner_html=` to set the inner html for a node
* Nokogiri builder interface improvements
* `Nokogiri::XML::Node#swap` swaps html for current node (LH [#50](https://github.com/sparklemotion/nokogiri/issues/50))

### Fixed

* Fixed a tag nesting problem in the Builder API (LH [#41](https://github.com/sparklemotion/nokogiri/issues/41))
* `Nokogiri::HTML.fragment` will properly handle text only nodes (LH [#43](https://github.com/sparklemotion/nokogiri/issues/43))
* `Nokogiri::XML::Node#before` will prepend text nodes (LH [#44](https://github.com/sparklemotion/nokogiri/issues/44))
* `Nokogiri::XML::Node#after` will append text nodes
* `Nokogiri::XML::Node#search` automatically registers root namespaces (LH [#42](https://github.com/sparklemotion/nokogiri/issues/42))
* `Nokogiri::XML::NodeSet#search` automatically registers namespaces
* `Nokogiri::HTML::NamedCharacters` delegates to libxml2
* `Nokogiri::XML::Node#[]` can take a symbol (LH [#48](https://github.com/sparklemotion/nokogiri/issues/48))
* vasprintf for windows updated.  Thanks Geoffroy Couprie!
* `Nokogiri::XML::Node#[]=` should not encode entities (LH [#55](https://github.com/sparklemotion/nokogiri/issues/55))
* Namespaces should be copied to reparented nodes (LH [#56](https://github.com/sparklemotion/nokogiri/issues/56))
* Nokogiri uses encoding set on the string for default in Ruby 1.9
* `Document#dup` should create a new document of the same type (LH [#59](https://github.com/sparklemotion/nokogiri/issues/59))
* `Document` should not have a parent method (LH [#64](https://github.com/sparklemotion/nokogiri/issues/64))


## 1.2.1 / 2009-02-23

### Fixed

* Fixed a CSS selector space bug
* Fixed Ruby 1.9 String Encoding (Thanks 角谷さん！)


## 1.2.0 / 2009-02-22

### Added

* CSS search now supports CSS3 namespace queries
* Namespaces on the root node are automatically registered
* CSS queries use the default namespace
* `Nokogiri::XML::Document#encoding` get encoding used for this document
* `Nokogiri::XML::Document#url` get the document url
* `Nokogiri::XML::Node#add_namespace` add a namespace to the node LH[#38](https://github.com/sparklemotion/nokogiri/issues/38)
* `Nokogiri::XML::Node#each` iterate over attribute name, value pairs
* `Nokogiri::XML::Node#keys` get all attribute names
* `Nokogiri::XML::Node#line` get the line number for a node (Thanks Dirkjan Bussink!)
* `Nokogiri::XML::Node#serialize` now takes an optional encoding parameter
* `Nokogiri::XML::Node#to_html`, to_xml, and to_xhtml take an optional encoding
* `Nokogiri::XML::Node#to_str`
* `Nokogiri::XML::Node#to_xhtml` to produce XHTML documents
* `Nokogiri::XML::Node#values` get all attribute values
* `Nokogiri::XML::Node#write_to` writes the node to an IO object with optional encoding
* `Nokogiri::XML::ProcessingInstruction.new`
* `Nokogiri::XML::SAX::PushParser` for all your push parsing needs.

### Fixed

* Fixed `Nokogiri::XML::Document#dup`
* Fixed header detection. Thanks rubikitch!
* Fixed a problem where invalid CSS would cause the parser to hang

### Deprecations

* `Nokogiri::XML::Node.new_from_str` will be deprecated in 1.3.0

### Changed

* `Nokogiri::HTML.fragment` now returns an XML::DocumentFragment (LH [#32](https://github.com/sparklemotion/nokogiri/issues/32))


## 1.1.1

### Added

* Added `XML::Node#elem?`
* Added `XML::Node#attribute_nodes`
* Added `XML::Attr`
* `XML::Node#delete` added.
* `XML::NodeSet#inner_html` added.

### Fixed

* Not including an HTML entity for \r for HTML nodes.
* Removed `CSS::SelectorHandler` and `XML::XPathHandler`
* `XML::Node#attributes` returns an `Attr` node for the value.
* `XML::NodeSet` implements `to_xml`


## 1.1.0

### Added

* Custom XPath functions are now supported.  See `Nokogiri::XML::Node#xpath`
* Custom CSS pseudo classes are now supported.  See `Nokogiri::XML::Node#css`
* `Nokogiri::XML::Node#<<` will add a child to the current node

### Fixed

* Mutex lock on CSS cache access
* Fixed build problems with GCC 3.3.5
* `XML::Node#to_xml` now takes an indentation argument
* `XML::Node#dup` takes an optional depth argument
* `XML::Node#add_previous_sibling` returns new sibling node.


## 1.0.7

### Fixed

* Fixed memory leak when using Dike
* SAX parser now parses IO streams
* Comment nodes have their own class
* `Nokogiri()` should delegate to `Nokogiri.parse()`
* Prepending rather than appending to `ENV['PATH']` on windows
* Fixed a bug in complex CSS negation selectors


## 1.0.6

### Fixed

* XPath Parser raises a `SyntaxError` on parse failure
* CSS Parser raises a `SyntaxError` on parse failure
* `filter()` and `not()` hpricot compatibility added
* CSS searches via `Node#search` are now always relative
* CSS to XPath conversion is now cached


## 1.0.5

### Fixed

* Added mailing list and ticket tracking information to the `README.txt`
* Sets `ENV['PATH']` on windows if it doesn't exist
* Caching results of `NodeSet#[]` on `Document`


## 1.0.4

### Fixed

* Changed memory management from weak refs to document refs
* Plugged some memory leaks
* Builder blocks can call methods from surrounding contexts


## 1.0.3

### Fixed

* `NodeSet` now implements `to_ary`
* `XML::Document` should not implement parent
* More GC Bugs fixed.  (Mike is AWESOME!)
* Removed RARRAY_LEN for 1.8.5 compatibility.  Thanks Shane Hanna.
* `inner_html` fixed. (Thanks Yehuda!)


## 1.0.2

### Fixed

* `extconf.rb` should not check for frex and racc


## 1.0.1

### Fixed

* Made sure `extconf.rb` searched libdir and prefix so that ports libxml/ruby will link properly.  Thanks lucsky!


## 1.0.0 / 2008-07-13

### Added

* Birthday!
