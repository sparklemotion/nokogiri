# Nokogumbo - a Nokogiri interface to the Gumbo HTML5 parser.

Nokogumbo provides the ability for a Ruby program to invoke the 
[Gumbo HTML5 parser](https://github.com/google/gumbo-parser#readme)
and to access the result as a
[Nokogiri::HTML::Document](http://rdoc.info/github/sparklemotion/nokogiri/Nokogiri/HTML/Document).

[![Build Status](https://travis-ci.org/rubys/nokogumbo.svg)](https://travis-ci.org/rubys/nokogumbo) 

## Usage

```ruby
require 'nokogumbo'
doc = Nokogiri::HTML5(string)
```

An experimental _fragment_ method is also provided.  While not HTML5
compliant, it may be useful:

```ruby
require 'nokogumbo'
doc = Nokogiri::HTML5.fragment(string)
```

Because HTML is often fetched via the web, a convenience interface to
HTTP get is also provided:

```ruby
require 'nokogumbo'
doc = Nokogiri::HTML5.get(uri)
```

## Error reporting
Nokogumbo contains an experimental parse error reporting facility. By default,
no parse errors are reported but this can be configured by passing the
`:max_errors` option to `::parse` or `::fragment`.

```ruby
require 'nokogumbo'
doc = Nokogiri::HTML5.parse('Hi there!<body>', max_errors: 10)
doc.errors.each do |err|
  puts err
end
```

This prints the following.
```
1:1: ERROR: @1:1: The doctype must be the first token in the document.
Hi there!<body>
^
1:10: ERROR: @1:10: That tag isn't allowed here  Currently open tags: html, body..
Hi there!<body>
         ^
```

The errors returned by `#errors` are instances of
[`Nokogiri::XML::SyntaxError`](https://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/SyntaxError).

## HTML Serialization

After parsing HTML, it may be serialized using any of the Nokogiri
[serialization
methods](https://www.rubydoc.info/gems/nokogiri/Nokogiri/XML/Node). In
particular, `#serialize`, `#to_html`, and `#to_s` will serialize a given node
and its children. (This is the equivalent of JavaScript's
`Element.outerHTML`.) Similarly, `#inner_html` will serialize the children of
a given node. (This is the equivalent of JavaScript's `Element.innerHTML`.)

``` ruby
doc = Nokogiri::HTML5("<!DOCTYPE html><span>Hello world!</span>")
puts doc.serialize
# Prints: <!DOCTYPE html><html><head></head><body><span>Hello world!</span></body></html>
```

Due to quirks in how HTML is parsed and serialized, it's possible for a DOM
tree to be serialized and then re-parsed, resulting in a different DOM.
Mostly, this happens with DOMs produced from invalid HTML. Unfortunately, even
valid HTML may not survive serialization and re-parsing.

In particular, a newline at the start of `pre`, `listing`, and `textarea`
elements is ignored by the parser.

``` ruby
doc = Nokogiri::HTML5(<<-EOF)
<!DOCTYPE html>
<pre>
Content</pre>
EOF
puts doc.at('/html/body/pre').serialize
# Prints: <pre>Content</pre>
```

In this case, the original HTML is semantically equivalent to the serialized
version. If the `pre`, `listing`, or `textarea` content starts with two
newlines, the first newline will be stripped on the first parse and the second
newline will be stripped on the second, leading to semantically different
DOMs. Passing the parameter `preserve_newline: true` will cause two or more
newlines to be preserved. (A single leading newline will still be removed.)

``` ruby
doc = Nokogiri::HTML5(<<-EOF)
<!DOCTYPE html>
<listing>

Content</listing>
EOF
puts doc.at('/html/body/listing').serialize(preserve_newline: true)
# Prints: <listing>
#
# Content</listing>
```


## Examples
```ruby
require 'nokogumbo'
puts Nokogiri::HTML5.get('http://nokogiri.org').search('ol li')[2].text
```

## Notes

* The `Nokogiri::HTML5.fragment` function takes a string and parses it
  as a HTML5 document.  The `<html>`, `<head>`, and `<body>` elements are
  removed from this document, and any children of these elements that remain
  are returned as a `Nokogiri::HTML::DocumentFragment`.
* The `Nokogiri::HTML5.parse` function takes a string and passes it to the
<code>gumbo_parse_with_options</code> method, using the default options.
The resulting Gumbo parse tree is then walked.
  * If the necessary Nokogiri and [libxml2](http://xmlsoft.org/html/) headers
    can be found at installation time then an
    [xmlDoc](http://xmlsoft.org/html/libxml-tree.html#xmlDoc) tree is produced
    and a single Nokogiri Ruby object is constructed to wrap the xmlDoc
    structure.  Nokogiri only produces Ruby objects as necessary, so all
    searching is done using the underlying libxml2 libraries.
  * If the necessary headers are not present at installation time, then
    Nokogiri Ruby objects are created for each Gumbo node.  Other than
    memory usage and CPU time, the results should be equivalent.

* The `Nokogiri::HTML5.get` function takes care of following redirects,
https, and determining the character encoding of the result, based on the
rules defined in the HTML5 specification for doing so.

* Instead of uppercase element names, lowercase element names are produced.

* Instead of returning `unknown` as the element name for unknown tags, the
original tag name is returned verbatim.

# Installation

    git clone https://github.com/rubys/nokogumbo.git
    cd nokogumbo
    bundle install
    rake gem
    gem install pkg/nokogumbo*.gem

# Related efforts

* [ruby-gumbo](https://github.com/nevir/ruby-gumbo#readme) -- a ruby binding
  for the Gumbo HTML5 parser.
* [lua-gumbo](https://gitlab.com/craigbarnes/lua-gumbo) -- a lua binding for
  the Gumbo HTML5 parser.
