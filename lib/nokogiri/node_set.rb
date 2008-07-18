module Nokogiri
  class NodeSet
    attr_accessor :xpath_ctx, :ptr

    class << self
      def wrap(ptr, ctx)
        ptr.struct!('IIP', :length, :max, :node_ptr)
        new() { |doc| doc.ptr = ptr; doc.xpath_ctx = ctx }
      end
    end

    def initialize
      yield self if block_given?
    end

    def length
      ptr[:length]
    end
  end
end
