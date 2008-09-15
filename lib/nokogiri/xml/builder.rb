module Nokogiri
  module XML
    class Builder
      attr_accessor :doc
      def initialize
        @doc = Nokogiri::XML::Document.new
        @node_stack = []
      end

      def method_missing(method, *args, &block)
        node = Nokogiri::XML::Node.new(method.to_s) { |n|
          n.content = args.first if args.first
        }
        if @node_stack.empty?
          @doc.root = node
        else
          node.parent = @node_stack.last
        end

        @node_stack << node
        instance_eval(&block) if block_given?
        @node_stack.pop
        nil
      end
    end
  end
end
