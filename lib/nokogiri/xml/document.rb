module Nokogiri
  module XML
    class Document < Node
      def decorators(key)
        @decorators ||= Hash.new
        @decorators[key] ||= []
      end

      def name
        'document'
      end

      def document
        self
      end

      ###
      # Apply any decorators to +node+
      def decorate(node)
        key = node.class.name.split('::').last.downcase
        decorators(key).each do |klass|
          node.extend(klass)
        end
      end

      def node_cache
        @node_cache ||= {}
      end

      def to_xml
        serialize
      end

      def inner_html
        serialize
      end

      def namespaces
        root ? root.collect_namespaces : {}
      end
    end
  end
end
