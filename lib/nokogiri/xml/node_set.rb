module Nokogiri
  module XML
    class NodeSet
      attr_accessor :xpath_ctx, :ptr, :to_a
      include Enumerable

      class << self
        def wrap(ptr, ctx)
          list = []
          ptr = DL::XML::NodeSet.new(ptr)
          if ptr.node_ptr
            list = ptr.node_ptr.to_a('P', ptr.length).map { |node_ptr|
              Node.wrap(node_ptr)
            }
          end

          new() { |doc| 
            doc.ptr = ptr
            doc.xpath_ctx = ctx
            doc.to_a = list
          }
        end
      end

      def initialize
        yield self if block_given?
      end

      def first
        to_a.first
      end

      def [](index)
        to_a[index]
      end
      alias :item :[]

      def each(&block)
        to_a.each(&block)
      end

      def search(path)
        xpath_obj = DL::XML::XPath.new(
          DL::XML.xmlXPathEvalExpression(
            DL::XML.xmlCharStrdup(path),
            xpath_ctx
          )
        )
        NodeSet.wrap(xpath_obj.nodeset, xpath_ctx)
      end

      def length
        to_a.length
      end
      alias :getLength :length

      def content
        map { |x| x.content }.join
      end
      alias :inner_text :content

      private
    end
  end
end
