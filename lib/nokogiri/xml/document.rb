module Nokogiri
  module XML
    class Document < Node
      attr_accessor :errors

      def name
        'document'
      end

      def document
        self
      end

      def decorators(key)
        @decorators ||= Hash.new
        @decorators[key] ||= []
      end

      ###
      # Explore a document with shortcut methods.
      def slop!
        unless decorators(XML::Node).include? Nokogiri::Decorators::Slop
          decorators(XML::Node) << Nokogiri::Decorators::Slop
          decorate!
        end

        self
      end

      ###
      # Apply any decorators to +node+
      def decorate(node)
        return unless @decorators
        @decorators.each { |klass,list|
          next unless node.is_a?(klass)
          list.each { |moodule| node.extend(moodule) }
        }
      end

      def node_cache
        @node_cache ||= {}
      end

      alias :to_xml :serialize
      alias :inner_html :serialize

      def namespaces
        root ? root.collect_namespaces : {}
      end
    end
  end
end
