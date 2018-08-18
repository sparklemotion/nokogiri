# Changelog

All notable changes to Nokogumbo will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added

### Changed
- Integrated [Gumbo parser](https://github.com/google/gumbo-parser) into
  Nokogumbo. A system version will not be used.

### Deprecated

### Removed

### Fixed
- Fixed documents failing to serialize (via `to_html`) if they contain certain
  `meta` elements that set the `charset`.
- Documents are now properly marked as UTF-8 after parsing.
- Fixed `Nokogiri::HTML5.fragment` reporting an error due to a missing
  `<!DOCTYPE html>`.

### Security
- The most recent, released version of Gumbo has a [potential security
  issue](https://github.com/google/gumbo-parser/pull/375) that could result in
  a cross-site scripting vulnerability. This has been fixed by integrating
  Gumbo into Nokogumbo.
