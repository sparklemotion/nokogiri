module Nokogiri
  class Node
    include Comparable
    include W3C::Org::Dom::Node

    HTML_DOCUMENT_NODE = 13
    DTD_NODE = 14
    ELEMENT_DECL = 15
    ATTRIBUTE_DECL = 16
    ENTITY_DECL = 17
    NAMESPACE_DECL = 18
    XINCLUDE_START = 19
    XINCLUDE_END = 20
    DOCB_DOCUMENT_NODE = 21

    class << self
      def wrap(ptr)
        new() { |doc| doc.ptr = NokogiriLib::XML::Node.new(ptr) }
      end
    end

    def initialize(type = nil)
      yield self if block_given?
      self.ptr ||=
        NokogiriLib::XML::Node.new(
          NokogiriLib::XML.xmlNewNode(nil, NokogiriLib::XML.xmlCharStrdup(type))
        )
    end

    attr_accessor :ptr

    def name; ptr.name.to_s; end
    def child; Node.wrap(ptr.children); end
    def next; Node.wrap(ptr.next); end

    def content
      NokogiriLib::XML.xmlNodeGetContent(ptr).to_s
    end
    alias :inner_text :content

    def content=(the_content)
      NokogiriLib::XML.xmlNodeSetContent(self,
                                    NokogiriLib::XML.xmlCharStrdup(the_content))
    end

    def path
      NokogiriLib::XML.xmlGetNodePath(ptr).to_s
    end

    def search(search_path)
      NokogiriLib::XML.xmlXPathInit
      xpath_ctx = NokogiriLib::XML.xmlXPathNewContext(ptr)
      xpath_obj = NokogiriLib::XML::XPath.new(
        NokogiriLib::XML.xmlXPathEvalExpression(
          NokogiriLib::XML.xmlCharStrdup(search_path),
          xpath_ctx
        )
      )
      return [] unless xpath_obj
      NodeSet.wrap(xpath_obj.nodeset, xpath_ctx)
    end
    alias :/ :search

    def [](property)
      property = NokogiriLib::XML.xmlGetProp(
        ptr,
        NokogiriLib::XML.xmlCharStrdup(property.to_s)
      )
      property && property.to_s
    end

    def []=(name, value)
      NokogiriLib::XML.xmlSetProp(
        ptr,
        NokogiriLib::XML.xmlCharStrdup(name.to_s),
        NokogiriLib::XML.xmlCharStrdup(value.to_s)
      )
    end

    def has_property?(attribute)
      !property(attribute).nil?
    end
    alias :has_attribute? :has_property?

    def property(attribute)
      NokogiriLib::XML.xmlHasProp(ptr, NokogiriLib::XML.xmlCharStrdup(attribute.to_s))
    end

    def blank?
      1 == NokogiriLib::XML.xmlIsBlankNode(ptr)
    end

    def root
      return nil unless ptr.doc

      root_element = NokogiriLib::XML.xmlDocGetRootElement(ptr.doc)
      root_element && Node.wrap(root_element)
    end

    def root=(root_node)
      NokogiriLib::XML.xmlDocSetRootElement(ptr.doc, root_node)
    end

    def root?
      self.<=>(self.root)
    end

    def xml?
      ptr.type == DOCUMENT_NODE
    end

    def html?
      ptr.type == HTML_DOCUMENT_NODE
    end

    def to_html
      serialize(:html)
    end

    def to_xml
      serialize(:xml)
    end

    def <=>(other)
      ptr.to_ptr <=> other.to_ptr
    end

    def to_ptr
      ptr.to_ptr
    end

    private
    def serialize(type = :xml)
      raise "No document set" unless ptr.doc
      msgpt = DL.malloc(DL.sizeof('P'))
      sizep = DL.malloc(DL.sizeof('I'))
      NokogiriLib::XML.send(:"#{type}DocDumpMemory", ptr.doc, msgpt.ref, sizep)
      msgpt.to_s
    end
  end
end
