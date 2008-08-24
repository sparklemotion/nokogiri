module Nokogiri
  class NodeSet
    attr_accessor :xpath_ctx, :ptr
    include Enumerable

    class << self
      def wrap(ptr, ctx)
        ptr = DL::XML::NodeSet.new(ptr)
        new() { |doc| doc.ptr = ptr; doc.xpath_ctx = ctx }
      end
    end

    def initialize
      yield self if block_given?
    end

    def first
      self.[](0)
    end

    def [](index)
      to_a[index]
    end

    def each(&block)
      to_a.each(&block)
    end

    def to_a
      to_ptr_a.map { |node_ptr|
        Node.wrap(node_ptr)
      }
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
      ptr.length
    end

    def content
      map { |x| x.content }.join
    end
    alias :inner_text :content

    private
    def to_ptr_a
      @ptr_a ||= (ptr.node_ptr ? ptr.node_ptr.to_a('P', ptr.length) : [])
    end
  end
end
