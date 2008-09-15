module Nokogiri
  module XML
    class Builder
      attr_accessor :doc
      def initialize(&block)
        namespace = self.class.name.split('::')
        namespace[-1] = 'Document'
        @doc = eval(namespace.join('::')).new
        @last_node = nil
        @root = true
        instance_eval(&block)
        @last_node = nil
        @root = true
      end

      def text(string)
        node = Nokogiri::XML::Text.new(string)
        insert(node)
      end

      def method_missing(method, *args, &block)
        node = Nokogiri::XML::Node.new(method.to_s) { |n|
          n.content = args.first if args.first
        }
        insert(node, &block)
      end

      private
      def insert(node, &block)
        if @root
          @root = false
          @doc.root = node
        else
          node.parent = @last_node
        end

        @last_node = node
        instance_eval(&block) if block_given?
        NodeBuilder.new(node, self)
      end

      class NodeBuilder # :nodoc:
        def initialize(node, doc_builder)
          @node = node
          @doc_builder = doc_builder
        end

        def method_missing(method, *args, &block)
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
          return @doc_builder.instance_eval(&block) if block_given?
          self
        end
      end
    end
  end
end
