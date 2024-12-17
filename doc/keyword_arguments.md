## Keyword Arguments

Many \Nokogiri methods take optional *positional* arguments.
Beginning in version 1.17.0 (December 2024),
some methods are being "modernized" to take optional *keyword* arguments,
which are far more versatile.

Example:

```ruby
# Before.
XML::Document.parse(xml_s, nil, nil, options)
# After.
XML::Document.parse(xml_s, options: options)
```

### About the Examples

Examples on this page assume that the following code has been executed:

```ruby
require 'nokogiri'
include Nokogiri
xml_s = '<root />'
url = 'www.site.com'
encoding = 'UTF-16'
options = XML::ParseOptions::STRICT
```

### Before

Before the changes, the calling sequence for a method might have
trailing optional positional arguments:

For example, the calling sequence `XML::Document.parse` was:

```
XML::Document.parse(
  # Required leading argument.
  input,
  # Optional positional arguments.
  url = nil,
  encoding = nil,
  options = XML::ParseOptions::DEFAULT_XML
  )
```

That calling sequence requires leading argument `input`,
and allows any of these:

- No optional arguments.
- Optional argument `url` only.
- Optional arguments `url` and `encoding` only.
- Optional arguments `url`, `encoding`, and `options`.

To pass arguments `input` and `options`,
a method call would also have to pass arguments `url` and `encoding`:

```
XML::Document.parse(xml_s, nil, nil, options)
```

### After

The updated calling sequence allows trailing *keyword* arguments.

The updated calling sequence for `XML::Document.parse`, for example,
allows optional keyword arguments `url`, `encoding`, and `options`.

The updated calling sequence may be thought of as:

```
XML::Document.parse(
  # Required leading argument.
  input,
  # Optional keyword arguments.
  url:,
  encoding:,
  options:
  )
```

where `url`, `encoding`, and `options` are optional keyword arguments.
Thus, to pass arguments `input` and `options`, 
a method call need only pass those two arguments (and not arguments `url` and `encoding`):

```ruby
XML::Document.parse(xml_s, options: options)
```

Each of the optional keyword arguments may be given or omitted;
they may be given in any combination and in any order:

```ruby
XML::Document.parse(xml_s, options: options, encoding: encoding, url: url)
```

The new calling sequence is fully compatible with the old,
so that this is still a valid call:

```ruby
XML::Document.parse(xml_s, url, encoding, options)
```

### Details

The updated calling sequence retains the optional positional arguments,
but adds trailing keyword arguments;
the default value for each keyword argument comes from the given (or default)
value of a positional argument.

The actual updated calling sequence for `XML::Document.parse`, for example, is:

```ruby
XML::Documnent.parse(
  # Required leading argument.
  input,
  # Optional positional arguments.
  url_ = nil,
  encoding_ = nil,
  options_ = XML::ParseOptions::DEFAULT_XML,
  # Optional keyword arguments; each defaults to a positional argument value.
  url: url_,
  encoding: encoding_,
  options: options_
)
```

Valid calls to the method include:

```ruby
# Positional arguments only.
XML::Document.parse(xml_s, url, encoding, options)
# Keyword arguments only, any order.
XML::Document.parse(xml_s, url: url, encoding: encoding, options: options)
XML::Document.parse(xml_s, encoding: encoding, options: options, url: url)
# Mixture of leading positional arguments and trailing keyword arguments.
XML::Document.parse(xml_s, url, options: options, encoding: encoding)
```
