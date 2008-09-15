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
        NodeBuilder.new(@node_stack.pop)
      end

      class NodeBuilder # :nodoc:
        def initialize(node)
          @node = node
        end

        def method_missing(method, *args)
          case method.to_s
          when /^(.*)!$/
            @node['id'] = $1
            @node.content = args.first if args.first
          when /^(.*)=/
            @node[$1] = args.first
          else
            @node['class'] = 
              ((@node['class'] || '').split(/\s/) + [method.to_s]).join(' ')
            @node.content = args.first if args.first
          end
          self
        end
      end
    end
  end
end
