# Parsing Strings

This page shows how Nokogiri parses an XML string into Nokogiri objects.
The string has text consisting of character data and markup.
For Nokogiri parsing, the string is given either by a String object
or by an IO object (which is read as a string).

On this page, each example uses method Nokogiri::XML.parse
to parse a string into a tree of Nokogiri objects.
The topmost object is a Nokogiri::XML::Document object,
which we will usually refer to as a document;
the document may have other objects as children.

## Text

## Markup

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

### Tag Attributes

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

### Comments

Nokogiri parses a comment into a Nokogiri::XML::Comment object.

A comment may be in a document or in a tag:

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


### CDATA Sections

### DocTypes

### Processing Instructions

### XML Declarations

### Text Declarations

### Entity References

### Character References


