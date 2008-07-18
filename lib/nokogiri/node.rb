module Nokogiri
  class Node
    XML_ELEMENT_NODE = 1
    XML_ATTRIBUTE_NODE = 2
    XML_TEXT_NODE = 3
    XML_CDATA_SECTION_NODE = 4
    XML_ENTITY_REF_NODE = 5
    XML_ENTITY_NODE = 6
    XML_PI_NODE = 7
    XML_COMMENT_NODE = 8
    XML_DOCUMENT_NODE = 9
    XML_DOCUMENT_TYPE_NODE = 10
    XML_DOCUMENT_FRAG_NODE = 11
    XML_NOTATION_NODE = 12
    XML_HTML_DOCUMENT_NODE = 13
    XML_DTD_NODE = 14
    XML_ELEMENT_DECL = 15
    XML_ATTRIBUTE_DECL = 16
    XML_ENTITY_DECL = 17
    XML_NAMESPACE_DECL = 18
    XML_XINCLUDE_START = 19
    XML_XINCLUDE_END = 20
    XML_DOCB_DOCUMENT_NODE = 21

    class << self
      def wrap(ptr)
        ptr.struct!('PISPPPPPP', :private, :type, :name, :children, :last, :parent, :next, :prev, :doc)
        new() { |doc| doc.ptr = ptr }
      end
    end

    def initialize
      yield self if block_given?
    end

    attr_accessor :ptr

    def name; ptr[:name].to_s; end
    def child; Node.wrap(ptr[:children]); end
    def next; Node.wrap(ptr[:next]); end

    def content
      NokogiriLib.xmlNodeGetContent(ptr).to_s
    end

    def [](property)
      property = NokogiriLib.xmlGetProp(
        ptr,
        NokogiriLib.xmlCharStrdup(property.to_s)
      )
      property && property.to_s
    end

    def blank?
      1 == NokogiriLib.xmlIsBlankNode(ptr)
    end
  end
end
