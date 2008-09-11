module Nokogiri
  module XML
    class Node
      include Comparable
      include W3C::Org::Dom::Node
      include W3C::Org::Dom::Element

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
          memory = DL::XML::Node.new(ptr)
          case memory.type
          when Node::TEXT_NODE
            Nokogiri::XML::TextNode
          else
            self
          end.new() { |doc| doc.ptr = DL::XML::Node.new(ptr) }
        end
      end

      def initialize(type = nil)
        yield self if block_given?
        self.ptr ||=
          DL::XML::Node.new(
            DL::XML.xmlNewNode(nil, DL::XML.xmlCharStrdup(type))
          )
      end

      attr_accessor :ptr

      def name; ptr.name.to_s; end
      def child; Node.wrap(ptr.children); end
      def next; ptr.next && Node.wrap(ptr.next); end
      def type; ptr.type; end

      alias :getFirstChild :child
      alias :getNextSibling :next
      alias :getNodeType :type

      def children
        list = []
        first = self.child
        list << first
        while first = first.next
          list << first
        end
        NodeSet.new { |s| s.to_a = list }
      end
      alias :getChildNodes :children

      def content
        DL::XML.xmlNodeGetContent(ptr).to_s
      end
      alias :inner_text :content
      alias :getNodeValue :content

      def content=(the_content)
        DL::XML.xmlNodeSetContent(self,
                                      DL::XML.xmlCharStrdup(the_content))
      end

      def path
        DL::XML.xmlGetNodePath(ptr).to_s
      end

      def search(search_path)
        DL::XML.xmlXPathInit
        xpath_ctx = DL::XML::XPathContext.new(DL::XML.xmlXPathNewContext(root))
        xpath_ctx.node = ptr.to_ptr
        xpath_ptr = DL::XML.xmlXPathEvalExpression(
            DL::XML.xmlCharStrdup(search_path),
            xpath_ctx
          )
        return [] unless xpath_ptr
        xpath_obj = DL::XML::XPath.new(xpath_ptr)
        NodeSet.wrap(xpath_obj.nodeset, xpath_ctx)
      end
      alias :/ :search

      def [](property)
        property = DL::XML.xmlGetProp(
          ptr,
          DL::XML.xmlCharStrdup(property.to_s)
        )
        property && property.to_s
      end

      def []=(name, value)
        DL::XML.xmlSetProp(
          ptr,
          DL::XML.xmlCharStrdup(name.to_s),
          DL::XML.xmlCharStrdup(value.to_s)
        )
      end

      def has_property?(attribute)
        !property(attribute).nil?
      end
      alias :has_attribute? :has_property?

      def property(attribute)
        DL::XML.xmlHasProp(ptr, DL::XML.xmlCharStrdup(attribute.to_s))
      end

      def blank?
        1 == DL::XML.xmlIsBlankNode(ptr)
      end

      def root
        return nil unless ptr.doc

        root_element = DL::XML.xmlDocGetRootElement(ptr.doc)
        root_element && Node.wrap(root_element)
      end

      def root=(root_node)
        DL::XML.xmlDocSetRootElement(ptr.doc, root_node)
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
      # this just dumps stripped content. is there an easy way to dump a subtree in xml? i don't know.
      def serialize_node(type = :xml)
        buffer = DL::XML::Buffer.new(DL::XML.xmlBufferCreate())
        DL::XML.xmlNodeDump(buffer, ptr.doc, ptr, 2, 1)
        x = content.dup.to_s
        DL::XML.xmlBufferFree(buffer)
        return x
      end

      def serialize(type = :xml)
        raise "No document set" unless ptr.doc
        msgpt = ::DL.malloc(::DL.sizeof('P'))
        sizep = ::DL.malloc(::DL.sizeof('I'))
        DL::XML.send(:"#{type}DocDumpMemory", ptr.doc, msgpt.ref, sizep)
        msgpt.to_s
      end
    end
  end
end
