module Nokogiri
  class Node
    include Comparable

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
        new() { |doc| doc.ptr = ptr }
      end
    end

    def initialize(type = nil)
      yield self if block_given?
      self.ptr ||= NokogiriLib.xmlNewNode(nil, NokogiriLib.xmlCharStrdup(type))
      self.ptr.struct!('PISPPPPPP', :private, :type, :name, :children, :last, :parent, :next, :prev, :doc)
    end

    attr_accessor :ptr
    alias :to_ptr :ptr

    def name; ptr[:name].to_s; end
    def child; Node.wrap(ptr[:children]); end
    def next; Node.wrap(ptr[:next]); end

    def content
      NokogiriLib.xmlNodeGetContent(ptr).to_s
    end
    alias :inner_text :content

    def content=(the_content)
      NokogiriLib.xmlNodeSetContent(self,
                                    NokogiriLib.xmlCharStrdup(the_content))
    end

    def path
      NokogiriLib.xmlGetNodePath(ptr).to_s
    end

    def search(search_path)
      NokogiriLib.xmlXPathInit
      xpath_ctx = NokogiriLib.xmlXPathNewContext(ptr)
      xpath_obj = NokogiriLib.xmlXPathEvalExpression(
        NokogiriLib.xmlCharStrdup(search_path),
        xpath_ctx
      )
      return [] unless xpath_obj
      xpath_obj.struct!('PP', :type, :nodeset)
      NodeSet.wrap(xpath_obj[:nodeset], xpath_ctx)
    end
    alias :/ :search

    def [](property)
      property = NokogiriLib.xmlGetProp(
        ptr,
        NokogiriLib.xmlCharStrdup(property.to_s)
      )
      property && property.to_s
    end

    def []=(name, value)
      NokogiriLib.xmlSetProp(
        ptr,
        NokogiriLib.xmlCharStrdup(name.to_s),
        NokogiriLib.xmlCharStrdup(value.to_s)
      )
    end

    def has_property?(attribute)
      !property(attribute).nil?
    end
    alias :has_attribute? :has_property?

    def property(attribute)
      NokogiriLib.xmlHasProp(ptr, NokogiriLib.xmlCharStrdup(attribute.to_s))
    end

    def blank?
      1 == NokogiriLib.xmlIsBlankNode(ptr)
    end

    def root
      return nil unless ptr[:doc]

      root_element = NokogiriLib.xmlDocGetRootElement(ptr[:doc])
      root_element && Node.wrap(root_element)
    end

    def root=(root_node)
      NokogiriLib.xmlDocSetRootElement(ptr[:doc], root_node)
    end

    def root?
      self.<=>(self.root)
    end

    def xml?
      ptr[:type] == XML_DOCUMENT_NODE
    end

    def html?
      ptr[:type] == XML_HTML_DOCUMENT_NODE
    end

    def to_html
      serialize(:html)
    end

    def to_xml
      serialize(:xml)
    end

    def <=>(other)
      ptr <=> other.ptr
    end

    private
    def serialize(type = :xml)
      raise "No document set" unless ptr[:doc]
      msgpt = DL.malloc(DL.sizeof('P'))
      sizep = DL.malloc(DL.sizeof('I'))
      NokogiriLib.send(:"#{type}DocDumpMemory", ptr[:doc], msgpt.ref, sizep)
      msgpt.to_s
    end
  end
end
