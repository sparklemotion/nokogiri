Nokogumbo - a Nokogiri interface to the Gumbo HTML5 parser.
===========

At the moment, this is a proof of concept, allowing a Ruby program to invoke
the Gumbo HTML5 parser and access the result as a Nokogiri parsed document.

Usage:
-----

```ruby
require 'nokogumbo'
doc = Nokogiri::HTML5(string)
```

Notes:
-----

* The `Nokogumbo.parse` function takes a string and passes it to the
<code>gumbo_parse_with_options</code> method, using the default options.
The resulting Gumbo parse tree is the walked, producing a Nokogiri parse tree.
The original Gumbo parse tree is then destroyed, and the Nokogiri parse tree
is returned. 

* Instead of uppercase element names, lowercase element names are produced.

* Instead of returning 'unknown' as the element name for unknown tags, the
original tag name is returned verbatim.

* Nothing meaningful is done with the `GumboDocument` struct, i.e., no
Nokogiri `EntityDecl` is produced.

* The gem itself includes a copy of the Nokogumbo HTML5 parser.

Installation:
============

* Execute `rake gem`

* [sudo] gem install pkg/nokogumbo*.gem

Related efforts:
============

* [ruby-gumbo](https://github.com/galdor/ruby-gumbo#readme) - a ruby binding
for the Gumbo HTML5 parser.
