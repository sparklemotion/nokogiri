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

### Prolog (XML Declaration)

### Document Type Declaration

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

#### Element Type Declarations

#### Attribute-List Declarations

#### Element Type Declarations

### Character References

### Entity References

#### Entity Declarations

#### Text Declaration

## Document Fragments
