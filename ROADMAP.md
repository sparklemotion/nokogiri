# Roadmap for API Changes

## overhaul serialize/pretty printing API

* [#530](https://github.com/sparklemotion/nokogiri/issues/530)
  XHTML formatting can't be turned off

* [#415](https://github.com/sparklemotion/nokogiri/issues/415)
  XML formatting should be no formatting


## overhaul and optimize the SAX parsing

* see fairy wing throwdown - SAX parsing is wicked slow.


## Node should not be Enumerable; and should have a better attributes API

* [#679](https://github.com/sparklemotion/nokogiri/issues/679)
  Mixing in Enumerable has some unintended consequences; plus we want to improve the attributes API

* Some ideas for a better attributes API?
    * (closed) [#666](https://github.com/sparklemotion/nokogiri/issues/666)
    * [#765](https://github.com/sparklemotion/nokogiri/issues/765)


## improve CSS query parsing

* [#528](https://github.com/sparklemotion/nokogiri/issues/528)
  support `:not()` with a nontrivial argument, like `:not(div p.c)`

* [#451](https://github.com/sparklemotion/nokogiri/issues/451)
  chained :not pseudoselectors

* better jQuery selector and CSS pseudo-selector support:
    * [#621](https://github.com/sparklemotion/nokogiri/issues/621)
    * [#342](https://github.com/sparklemotion/nokogiri/issues/342)
    * [#628](https://github.com/sparklemotion/nokogiri/issues/628)
    * [#652](https://github.com/sparklemotion/nokogiri/issues/652)
    * [#688](https://github.com/sparklemotion/nokogiri/issues/688)

* [#394](https://github.com/sparklemotion/nokogiri/issues/394)
  nth-of-type is wrong, and possibly other selectors as well

* [#309](https://github.com/sparklemotion/nokogiri/issues/309)
  incorrect query being executed

* [#350](https://github.com/sparklemotion/nokogiri/issues/350)
  :has is wrong?


## DocumentFragment

* there are a few tickets about searches not working properly if you
  use or do not use the context node as part of the search.
    - [#213](https://github.com/sparklemotion/nokogiri/issues/213)
    - [#370](https://github.com/sparklemotion/nokogiri/issues/370)
    - [#454](https://github.com/sparklemotion/nokogiri/issues/454)
    - [#572](https://github.com/sparklemotion/nokogiri/issues/572)
  could we fix this by making DocumentFragment be a subclass of NodeSet?


## Better Syntax for custom XPath function handler

* [PR#464](https://github.com/sparklemotion/nokogiri/issues/464)


## Better Syntax around Node#xpath and NodeSet#xpath

* look at those methods, and use of Node#extract_params in Node#{css,search}
    * we should standardize on a hash of options for these and other calls
* what should NodeSet#xpath return?
    * [#656](https://github.com/sparklemotion/nokogiri/issues/656)

## Encoding

We have a lot of issues open around encoding. How bad are things?
Somebody who knows encoding well should head this up.

* Extract EncodingReader as a real object that can be injected
  https://groups.google.com/forum/#!msg/nokogiri-talk/arJeAtMqvkg/tGihB-iBRSAJ


## Reader

It's fundamentally broken, in that we can't stop people from crashing
their application if they want to use object reference unsafely.


## Class methods that require Document

There are a few methods, like `Nokogiri::XML::Comment.new` that
require a Document object.

We should probably make Document instance methods to wrap this, since
it's a non-obvious expectation and thus fails as a convention.

So, instead, let's make alternative methods like
`Nokogiri::XML::Document#new_comment`, and recommend those as the
proper convention.


## `collect_namespaces` is just broken

`collect_namespaces` is returning a hash, which means it can't return
namespaces with the same prefix. See this issue for background:

> [#885](https://github.com/sparklemotion/nokogiri/issues/885)

Do we care? This seems like a useless method, but then again I hate
XML, so what do I know?


## Overhaul `ParseOptions`

Currently we mirror libxml2's parse options, and then retrofit those options on top of Xerces-J for JRuby.

* I'd like to identify which options work across both parsers,
* And overhaul the parse methods so that these options are easier to use.

By "easier to use" I mean:

* it's unwieldy to create a block to set/unset parse options
* it's unwieldy to create a constant like `MY_PARSE_OPTIONS = Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::RECOVER ...`
* some options are named dangerously poorly, like `NOENT` which [does the opposite of what it says](https://github.com/sparklemotion/nokogiri/issues/1582#issuecomment-562180275)
* semantically some options should be set/unset together, specifically "this is a trusted document" or "this is an untrusted document" should flip the senses of `NONET` and `NOENT` and `DTDLOAD` together.
* we need the ability to invent new parse options, like the one suggested in [#1582](https://github.com/sparklemotion/nokogiri/issues/1582) that would allow local entities but not external entities.
