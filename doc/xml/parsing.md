# Parsing

This page shows how \Nokogiri parses an XML string into \Nokogiri objects.
The string has text consisting of character data and markup.
For a \Nokogiri parsing method, the string is passed
either as a [String](https://docs.ruby-lang.org/en/master/String.html) object
or as an [IO](https://docs.ruby-lang.org/en/master/IO.html) object
from which the string is to be read.

Most of the sections below link to a relevant section in the W3C document
[Extensible Markup Language (XML) 1.0 (Fifth Edition)](https://www.w3.org/TR/REC-xml/).


On this page, each example uses either:

- Method Nokogiri::XML::parse (shorthand for Nokogiri::XML::Document.parse)
  to parse a string into a tree of \Nokogiri objects.
  The topmost object is a Nokogiri::XML::Document object,
  which we will usually refer to as a document;
  the document may have other objects as children.

- Method Nokogiri::XML::DocumentFragment.parse
  to parse a string into a tree of \Nokogiri objects.
  The topmost object is a Nokogiri::XML::DocumentFragment object,
  which we will usually refer to as a fragment;
  the fragment may have other objects as children.

## Text

The string to be parsed is text, consisting of
[character data and markup](https://www.w3.org/TR/REC-xml/#syntax).

## Character Data

All text that is not markup it character data.

## Markup

### Comments

\Nokogiri parses an [XML comment](https://www.w3.org/TR/REC-xml/#sec-comments)
into a Nokogiri::XML::Comment object.

A comment may be in the document itself or in a tag:

```
xml = '<!-- Comment. --><root><!-- Another comment. --></root>'
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(Comment " Comment. "),
    #(Element: {
      name = "root",
      children = [ #(Comment " Another comment. ")]
      })]
  })
```

### Processing Instructions

\Nokogiri parses an [XML processing instruction](https://www.w3.org/TR/REC-xml/#sec-pi)
into a Nokogiri::XML::ProcessingInstruction object:

```
xml = '<?xml-stylesheet type="text/xsl" href="style.xsl"?>'
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(ProcessingInstruction: {
      name = "xml-stylesheet"
      })]
  })
```

### CDATA Sections

\Nokogiri parses an [XML CDATA section](https://www.w3.org/TR/REC-xml/#sec-cdata-sect)
into a Nokogiri::XML::CDATA object:

```
xml = '<root><![CDATA[<greeting>Hello, world!</greeting>]]></root>'
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(Element: {
      name = "root",
      children = [
        #(CDATA "<greeting>Hello, world!</greeting>")]
      })]
  })
```

### Prolog (XML Declaration)

\Nokogiri parses an [XML declaration](https://www.w3.org/TR/REC-xml/#sec-prolog-dtd)
into values put onto the parsed document:

```
xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
doc = Nokogiri::XML.parse(xml)
doc.version  # => "1.0"
doc.encoding # => "UTF-8"
```

### Document Type Declaration

\Nokogiri parses an [XML document type declaration](https://www.w3.org/TR/REC-xml/#sec-prolog-dtd)
into a Nokogiri::XML::DTD object:

```
xml = '<!DOCTYPE greeting SYSTEM "hello.dtd">'
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [ #(DTD: { name = "greeting" })]
  })
  ```

### Tags

\Nokogiri parses an [XML tag](https://www.w3.org/TR/REC-xml/#sec-starttags)
into a Nokogiri::XML::Element object.

In this example, a single tag is parsed into a document whose only child
is the root element parsed from the tag:

```
xml = '<root/>'
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [ #(Element: { name = "root" })]
  })
```

A tag may have nested tags:

```
xml = '<root><foo><goo/><moo/></foo><bar><car/><far/></bar></root>'
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(Element: {
      name = "root",
      children = [
        #(Element: {
          name = "foo",
          children = [
            #(Element: { name = "goo" }),
            #(Element: { name = "moo" })]
          }),
        #(Element: {
          name = "bar",
          children = [
            #(Element: { name = "car" }),
            #(Element: { name = "far" })]
          })]
      })]
  })
```

A tag may have nested text:

```
xml = '<root>One<foo>Two</foo>Three<bar>Four</bar>Five</root>'
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(Element: {
      name = "root",
      children = [
        #(Text "One"),
        #(Element: {
          name = "foo",
          children = [ #(Text "Two")]
          }),
        #(Text "Three"),
        #(Element: {
          name = "bar",
          children = [ #(Text "Four")]
          }),
        #(Text "Five")]
      })]
  })
```

A tag may have nested markup of other types (such as comments):

```
xml = '<root><foo/><!-- Comment text. --><bar/></root>'
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(Element: {
      name = "root",
      children = [
        #(Element: { name = "foo" }),
        #(Comment " Comment text. "),
        #(Element: { name = "bar" })]
      })]
  })
```

### Tag Attributes

\Nokogiri parses an [XML tag attribute](https://www.w3.org/TR/REC-xml/#NT-Attribute)
into a Nokogiri::XML::Attr object:

```
xml = '<root foo="0" bar="1"/>'
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(Element: {
      name = "root",
      attribute_nodes = [
        #(Attr: { name = "foo", value = "0" }),
        #(Attr: { name = "bar", value = "1" })]
      })]
  })
```

### Element Type Declarations

\Nokogiri parses an [XML element type declaration](https://www.w3.org/TR/REC-xml/#elemdecls)
into a Nokogiri::XML::ElementDecl object:

```
xml = <<DOCTYPE
<!DOCTYPE note [
<!ELEMENT note (to,from,heading,body)>
<!ELEMENT to (#PCDATA)>
<!ELEMENT from (#PCDATA)>
<!ELEMENT heading (#PCDATA)>
<!ELEMENT body (#PCDATA)>
]>
DOCTYPE
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(DTD: {
      name = "note",
      children = [
        #(ElementDecl: { "<!ELEMENT note (to , from , heading , body)>\n" }),
        #(ElementDecl: { "<!ELEMENT to (#PCDATA)>\n" }),
        #(ElementDecl: { "<!ELEMENT from (#PCDATA)>\n" }),
        #(ElementDecl: { "<!ELEMENT heading (#PCDATA)>\n" }),
        #(ElementDecl: { "<!ELEMENT body (#PCDATA)>\n" })]
      })]
  })
  ```

### Attribute-List Declarations

\Nokogiri parses an [XML attribute-list declaration](https://www.w3.org/TR/REC-xml/#attdecls)
into a Nokogiri::XML::AttributeDecl object:

```
xml = <<DOCTYPE
<!DOCTYPE note [
<!ELEMENT payment (#PCDATA)>
<!ATTLIST payment type CDATA "check">
]>
DOCTYPE
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(DTD: {
      name = "note",
      children = [
        #(ElementDecl: { "<!ELEMENT payment (#PCDATA)>\n" }),
        #(AttributeDecl: { "<!ATTLIST payment type CDATA \"check\">\n" })]
      })]
  })
```

### Conditional Sections

\Nokogiri parses an [XML conditional section](https://www.w3.org/TR/REC-xml/#sec-condition-sect)
into a Nokogiri::XML::EntityDecl object:

```
xml = <<DOCTYPE
<!DOCTYPE note [
<!ENTITY % draft 'INCLUDE' >
]>
DOCTYPE
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(DTD: {
      name = "note",
      children = [ #(EntityDecl: { "<!ENTITY % draft \"INCLUDE\">\n" })]
      })]
  })
```

### Character References

\Nokogiri parses an [XML character reference](https://www.w3.org/TR/REC-xml/#sec-references)
(such as <tt>&amp;9792;</tt>)
and replaces it with a character such as (<tt>'♀'</tt>):

```
xml = <<ELE
<root>
  <name>
    <vorname>Marie</vorname>
    <nachname>M&#252;ller</nachname>
    <geschlecht>&#9792;</geschlecht>
  </name>
</root>
ELE
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(Element: {
      name = "root",
      children = [
        #(Text "\n  "),
        #(Element: {
          name = "name",
          children = [
            #(Text "\n    "),
            #(Element: { name = "vorname", children = [ #(Text "Marie")] }),
            #(Text "\n    "),
            #(Element: { name = "nachname", children = [ #(Text "Müller")] }),
            #(Text "\n    "),
            #(Element: { name = "geschlecht", children = [ #(Text "♀")] }),
            #(Text "\n  ")]
          }),
        #(Text "\n")]
      })]
  })
```

### Entity References

\Nokogiri parses an [XML entity reference](https://www.w3.org/TR/REC-xml/#sec-references)
(such as <tt>&amp;lt;</tt>)
and replaces it with text such as (<tt>'<'</tt>):

```
xml = '<root>An entity reference is needed for the less-than character (&lt;).</root>'
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(Element: {
      name = "root",
      children = [ #(Text "An entity reference is needed for the less-than character (<).")]
      })]
  })
```

### Entity Declarations

\Nokogiri parses an [XML entity declaration](https://www.w3.org/TR/REC-xml/#sec-entity-decl)
into a Nokogiri::XML::EntityDecl object:

```
xml = <<DTD
<!DOCTYPE note [
  <!ENTITY company "Example Corp">
]>
DTD
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(DTD: {
      name = "note",
      children = [ #(EntityDecl: { "<!ENTITY company \"Example Corp\">\n" })]
      })]
  })
```

## Document Fragments

When an XML string has more than one top-level tag,
\Nokogiri *document parsing* captures only the first top-level tag
(which becomes the root element)
and ignores other top-level tags (and their children);
this may not be the desired result:

```
xml = <<FRAGMENT
<top0>
  <ele0/>
  <ele1/>
</top0>
<top1/>
<top2/>
FRAGMENT
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document: {
  name = "document",
  children = [
    #(Element: {
      name = "top0",
      children = [
        #(Text "\n  "),
        #(Element: { name = "ele0" }),
        #(Text "\n  "),
        #(Element: { name = "ele1" }),
        #(Text "\n")]
      })]
  })```

To capture all top-level tags, use \Nokogiri *fragment parsing*
via method Nokogiri::XML::DocumentFragment.parse:

```
xml = <<FRAGMENT
<top0>
  <ele0/>
  <ele1/>
</top0>
<top1/>
<top2/>
FRAGMENT
fragment = Nokogiri::XML::DocumentFragment.parse(xml)
fragment
# =>
#(DocumentFragment: {
  name = "#document-fragment",
  children = [
    #(Element: {
      name = "top0",
      children = [
        #(Text "\n  "),
        #(Element: { name = "ele0" }),
        #(Text "\n  "),
        #(Element: { name = "ele1" }),
        #(Text "\n")]
      }),
    #(Text "\n"),
    #(Element: { name = "top1" }),
    #(Text "\n"),
    #(Element: { name = "top2" }),
    #(Text "\n")]
  })
```

Note that:

- The returned object is a Nokogiri::XML::DocumentFragment object
  (not a Nokigiri::XML::Document object).
- The fragment has three children of class Nokogiri::XML::Element
  (which in a document is not allowed).
