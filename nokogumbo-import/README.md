Nokogumbo - a Nokogiri interface to the Gumbo HTML5 parser.
===========

Nokogumbo provides the ability for a Ruby program to invoke the 
[Gumbo HTML5 parser](https://github.com/google/gumbo-parser#readme)
and to access the result as a
[Nokogiri::HTML::Document](http://nokogiri.org/Nokogiri/HTML/Document.html).

Usage
-----

```ruby
require 'nokogumbo'
doc = Nokogiri::HTML5(string)
```

Because HTML is often fetched via the web, a convenience interface to
HTTP get is also provided:

```ruby
require 'nokogumbo'
doc = Nokogiri::HTML5.get(uri)
```

Example
-----
```ruby
require 'nokogumbo'
puts Nokogiri::HTML5.get('http://nokogiri.org').at('h1 abbr')['title']
```

Notes
-----

* The `Nokogiri::HTML5.parse` function takes a string and passes it to the
<code>gumbo_parse_with_options</code> method, using the default options.
The resulting Gumbo parse tree is the walked, producing a 
[libxml2](http://xmlsoft.org/html/)
[xmlDoc](http://xmlsoft.org/html/libxml-tree.html#xmlDoc).
The original Gumbo parse tree is then destroyed, and single Nokogiri Ruby
object is constructed to wrap the xmlDoc structure.  Nokogiri only produces
Ruby objects as necessary, so all searching is done using the underlying
libxml2 libraries.

* The `Nokogiri::HTML5.get` function takes care of following redirects,
https, and determining the character encoding of the result, based on the
rules defined in the HTML5 specification for doing so.

* Instead of uppercase element names, lowercase element names are produced.

* Instead of returning `unknown` as the element name for unknown tags, the
original tag name is returned verbatim.

* If the Gumbo HTML5 parser is not already installed, the source for the
parser will be downloaded and compiled into the Gem itself.

Installation
============

* Execute `rake gem`

* [sudo] gem install pkg/nokogumbo*.gem

Related efforts
============

* [ruby-gumbo](https://github.com/galdor/ruby-gumbo#readme) - a ruby binding
for the Gumbo HTML5 parser.
