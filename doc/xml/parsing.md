# Parsing

This page shows how \Nokogiri parses an XML string into \Nokogiri objects.
The string has text consisting of character data and markup.
For a \Nokogiri parsing method, the string is passed
either as a [String](https://docs.ruby-lang.org/en/master/String.html) object
or as an [IO](https://docs.ruby-lang.org/en/master/IO.html) object
from which the string is to be read.

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

The string to be parsed is text, consisting of character data and markup.

## Character Data

All text that is not markup it character data.

## Markup

### Comments

\Nokogiri parses a comment into a Nokogiri::XML::Comment object.

A comment may be in the document itself or in a tag:

```
xml = '<!-- Comment. --><root><!-- Another comment. --></root>'
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document:0xa04c0 {
  name = "document",
  children = [
    #(Comment " Comment. "),
    #(Element:0xa0560 {
      name = "root",
      children = [ #(Comment " Another comment. ")]
      })]
  })
```

### Processing Instructions

\Nokogiri parses a processing instruction into a Nokogiri::XML::ProcessingInstruction object:

```
xml = '<?xml-stylesheet type="text/xsl" href="style.xsl"?>'
# => "<?xml-stylesheet type=\"text/xsl\" href=\"style.xsl\"?>"
doc = Nokogiri::XML.parse(xml)
# =>
#(Document:0x4da8 {
...
doc
# =>
#(Document:0x4da8 {
  name = "document",
  children = [
    #(ProcessingInstruction:0x4e20 {
      name = "xml-stylesheet"
      })]
  })
```

### CDATA Sections

\Nokogiri parses a CDATA section into a Nokogiri::XML::CDATA object:

```
xml = '<root><![CDATA[<greeting>Hello, world!</greeting>]]></root>'
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document:0x8dd8 {
  name = "document",
  children = [
    #(Element:0x8e50 {
      name = "root",
      children = [
        #(CDATA "<greeting>Hello, world!</greeting>")]
      })]
  })
```

### Prolog (XML Declaration)

\Nokogiri parses an XML declaration into values put onto the parsed document:

```
xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
doc = Nokogiri::XML.parse(xml)
doc
# => #(Document:0x17300 { name = "document" })
doc.version  # => "1.0"
doc.encoding # => "UTF-8"
```

### Document Type Declaration

\Nokogiri parses a document type declaration into a Nokogiri::XML::DTD object:

```
xml = '<!DOCTYPE greeting SYSTEM "hello.dtd">'
doc = Nokogiri::XML.parse(xml)
doc
# =>
#(Document:0x32a38 {
  name = "document",
  children = [ #(DTD:0x32ab0 { name = "greeting" })]
  })
  ```

### Tags

Nokogiri parses a tag into a Nokogiri::XML::Element object.

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

#### Tag Attributes

Nokogiri parses a tag attribute into a Nokogiri::XML::Attr object.

```
xml = '<root foo="0" bar="1"/>'
# => "<root foo=\"0\" bar=\"1\"/>"
doc = Nokogiri::XML.parse(xml)
# =>
#(Document:0xa5d30 {
...
doc
# =>
#(Document:0xa5d30 {
  name = "document",
  children = [
    #(Element:0xa5da8 {
      name = "root",
      attribute_nodes = [
        #(Attr:0xa5e20 { name = "foo", value = "0" }),
        #(Attr:0xa5ec8 { name = "bar", value = "1" })]
      })]
  })
```

### Element Type Declarations

\Nokogiri parses an element type declaration into a Nokogiri::XML::ElementDecl object:

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
#(Document:0x2a330 {
  name = "document",
  children = [
    #(DTD:0x2a3a8 {
      name = "note",
      children = [
        #(ElementDecl:0x2a420 { "<!ELEMENT note (to , from , heading , body)>\n" }),
        #(ElementDecl:0x2a460 { "<!ELEMENT to (#PCDATA)>\n" }),
        #(ElementDecl:0x2a4a0 { "<!ELEMENT from (#PCDATA)>\n" }),
        #(ElementDecl:0x2a4e0 { "<!ELEMENT heading (#PCDATA)>\n" }),
        #(ElementDecl:0x2a520 { "<!ELEMENT body (#PCDATA)>\n" })]
      })]
  })
  ```

### Attribute-List Declarations

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
#(Document:0x4a430 {
  name = "document",
  children = [
    #(DTD:0x4a4a8 {
      name = "note",
      children = [
        #(ElementDecl:0x4a520 { "<!ELEMENT payment (#PCDATA)>\n" }),
        #(AttributeDecl:0x4a560 { "<!ATTLIST payment type CDATA \"check\">\n" })]
      })]
  })
```

### Conditional Sections

### Character References

### Entity References

#### Entity Declarations

#### Text Declaration

## Document Fragments
