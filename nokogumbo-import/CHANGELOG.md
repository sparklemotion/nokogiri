# Changelog

All notable changes to Nokogumbo will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Experimental support for errors (it was supported in 1.5.0 but
  undocumented).

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
  In all cases, `html` can be a string or an `IO` object (something that
  responds to `#read`). The `url` parameter is entirely for error reporting,
  as in Nokogiri. The `encoding` parameter only signals what encoding `html`
  should have on input; the output `Document` or `DocumentFragment` will be in
  UTF-8. Currently, the only options supported is `:max_errors` which controls
  the maximum number of reported by `#errors`.

### Deprecated
- `:max_parse_errors`; use `:max_errors`

### Removed

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
