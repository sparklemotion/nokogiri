module Nokogiri
  module XML
    class Builder
      attr_accessor :doc, :parent
      def initialize(&block)
        namespace = self.class.name.split('::')
        namespace[-1] = 'Document'
        @doc = eval(namespace.join('::')).new
        @parent = @doc
        @context = eval('self', block.binding)
        instance_eval(&block)
        @parent = @doc
      end

      def text(string)
        node = Nokogiri::XML::Text.new(string, @doc)
        insert(node)
      end

      def cdata(string)
        node = Nokogiri::XML::CDATA.new(@doc, string)
        insert(node)
      end

      def to_xml
        @doc.to_xml
      end

      def method_missing(method, *args, &block)
        if @context.respond_to?(method)
          @context.send(method, *args, &block)
        else
          node = Nokogiri::XML::Node.new(method.to_s, @doc) { |n|
            if content = args.first
              if content.is_a?(Hash)
                content.each { |k,v| n[k.to_s] = v.to_s }
              else
                n.content = content
              end
            end
          }
          insert(node, &block)
        end
      end

      private
      def insert(node, &block)
        node.parent = @parent
        if block_given?
          @parent = node
          instance_eval(&block)
          @parent = node.parent
        end
        NodeBuilder.new(node, self)
      end

      class NodeBuilder # :nodoc:
        def initialize(node, doc_builder)
          @node = node
          @doc_builder = doc_builder
        end

        def method_missing(method, *args, &block)
          opts = args.last.is_a?(Hash) ? args.pop : {}
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

          # Assign any extra options
          opts.each do |k,v|
            @node[k.to_s] = ((@node[k.to_s] || '').split(/\s/) + [v]).join(' ')
          end

          if block_given?
            old_parent = @doc_builder.parent
            @doc_builder.parent = @node
            value = @doc_builder.instance_eval(&block)
            @doc_builder.parent = old_parent
            return value
          end
          self
        end
      end
    end
  end
end
