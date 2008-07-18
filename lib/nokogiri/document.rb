module Nokogiri
  # Wraps xmlDocPtr
  class Document < Node
    class << self
      def wrap(ptr)
        ptr.struct!('PISPPPPPP', :private, :type, :name, :children, :last, :parent, :next, :prev, :doc)
        new() { |doc| doc.ptr = ptr }
      end
    end

    attr_accessor :ptr

    def initialize
      yield self if block_given?
    end

    def root
      Node.new(NokogiriLib.xmlDocGetRootElement(@ptr))
    end

    def xml?
      ptr[:type] == XML_DOCUMENT_NODE
    end

    def html?
      ptr[:type] == XML_HTML_DOCUMENT_NODE
    end
  end
end
