# Changelog

All notable changes to Nokogumbo will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security

## [2.0.4] - 2020-11-27
### Fixed
- Fixed a bug where `Nokogiri::HTML5.fragment(nil)` would raise an error. Now
  it returns an empty `DocumentFragment` like it did in v2.0.2.
- Fixed assertion failure when a tag immediately followed the UTF-8 BOM.


## [2.0.3] - 2020-11-21
### Added
- Limit enforced on number of attributes per element, defaulting to 400 and
  configurable with the `:max_attributes` argument.
### Fixed
- Ignore UTF-8 byte order mark at the beginning of the input.
- Fix content sniffing for Unicode strings.
- Fixed crash where Ruby objects constructed in C can be garbage collected.

## [2.0.2] - 2019-11-19
### Added
- Support Ruby 2.6
### Fixed
- Fix assertion failures with nonstandard HTML tags.
- Fix the handling of mis-nested formatting tags (the adoption agency
  algorithm).
- Fix crash with zero-length HTML tags.
### Security
- Prevent 1-byte buffer over read when constructing an error message about an
  unexpected EOF.

## [2.0.1] - 2018-11-11
### Fixed
- Fix line numbers on elements from `#line`.

## [2.0.0] - 2018-10-04
### Added
- Experimental support for errors (it was supported in 1.5.0 but
  undocumented).
- Added proper HTML5 serialization.
- Added option `:max_errors` to control the maximum number of errors reported
  by `#errors`.
- Added option `:max_tree_depth` to control the maximum parse tree depth.
- Line number support via `Nokogiri::XML::Node#line` as long as Nokogumbo has
  been compiled with libxml2 support.

### Changed
- Integrated [Gumbo parser](https://github.com/google/gumbo-parser) into
  Nokogumbo. A system version will not be used.
- The undocumented (but publicly mentioned) `:max_parse_errors` renamed to `:max_errors`;
  `:max_parse_errors` is deprecated and will go away
- The various `#parse` and `#fragment` (and `Nokogiri.HTML5`) methods return
  `Nokogiri::HTML5::Document` and `Nokogiri::HTML5::DocumentFragment` classes
  rather than `Nokogiri::HTML::Document` and
  `Nokogiri::HTML::DocumentFragment`.
- Changed the top-level API to more closely match Nokogiri's while maintaining
  backwards compatibility. The new APIs are
  * `Nokogiri::HTML5(html, url = nil, encoding = nil, **options, &block)`
  * `Nokogiri::HTML5.parse(html, url = nil, encoding = nil, **options, &block)`
  * `Nokogiri::HTML5::Document.parse(html, url = nil, encoding = nil, **options, &block)`
  * `Nokogiri::HTML5.fragment(html, encoding = nil, **options)`
  * `Nokogiri::HTML5::DocumentFragment.parse(html, encoding = nil, **options)`
  * `Nokogiri::HTML5::DocumentFragment.new(document, html = nil, ctx = nil)`
  * `Nokogiri::HTML5::Document#fragment(html = nil)`
  * `Nokogiri::XML::Node#fragment(html = nil)`
  In all cases, `html` can be a string or an `IO` object (something that
  responds to `#read`). The `url` parameter is entirely for error reporting,
  as in Nokogiri. The `encoding` parameter only signals what encoding `html`
  should have on input; the output `Document` or `DocumentFragment` will be in
  UTF-8. Currently, the only options supported are `:max_errors` which controls
  the maximum number of reported by `#errors`.
- Minimum supported version of Ruby changed to 2.1.
- Minimum supported version of Nokogiri changed to 1.8.0.
- `Nokogiri::HTML5::DocumentFragment#errors` returns errors for the document
  fragment itself, not the underlying document.
- The five XML namespaces described in the HTML spec, MathML, SVG, XLink, XML,
  and XMLNS, are now supported. Thus `<svg>` will create an `svg` element in
  the SVG namespace and `<math>` will create a `math` element in the MathML
  namespace. An attribute `xml:lang=en`, for example, will create a `lang`
  attribute in the XML namespace, **but only in foreign elements (i.e., those
  in the SVG or MathML namespaces)**. On HTML elements, this creates an
  attribute with the name `xml:lang`. This changes the `#xpath` and related
  APIs.
- Calling `#to_xml` on a `Nokogiri::HTML5::Document` will produce XML output
  rather than HTML.

### Deprecated
- `:max_parse_errors`; use `:max_errors`

### Fixed
- Fixed documents failing to serialize (via `to_html`) if they contain certain
  `meta` elements that set the `charset`.
- Documents are now properly marked as UTF-8 after parsing.
- Fixed `Nokogiri::HTML5.fragment` reporting an error due to a missing
  `<!DOCTYPE html>`.
- Fixed crash when input contains U+0000 NULL bytes and error reporting is
  enabled.

### Security
- The most recent, released version of Gumbo has a [potential security
  issue](https://github.com/google/gumbo-parser/pull/375) that could result in
  a cross-site scripting vulnerability. This has been fixed by integrating
  Gumbo into Nokogumbo.
