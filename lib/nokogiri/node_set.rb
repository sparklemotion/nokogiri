module Nokogiri
  class NodeSet
    attr_accessor :xpath_ctx, :ptr
    include Enumerable

    class << self
      def wrap(ptr, ctx)
        ptr.struct!('IIP', :length, :max, :node_ptr)
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
      Node.wrap(to_ptr_a[index])
    end

    def each(&block)
      to_ptr_a.each do |node_ptr|
        block.call(Node.wrap(node_ptr))
      end
    end

    def search(path)
      xpath_obj = NokogiriLib.xmlXPathEvalExpression(
        NokogiriLib.xmlCharStrdup(path),
        xpath_ctx
      )
      xpath_obj.struct!('PP', :type, :nodeset)
      NodeSet.wrap(xpath_obj[:nodeset], xpath_ctx)
    end

    def length
      ptr[:length]
    end

    private
    def to_ptr_a
      @ptr_a ||= ptr[:node_ptr].to_a('P', ptr[:length])
    end
  end
end
