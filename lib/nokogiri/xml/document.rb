module Nokogiri
  module XML
    class Document < Node
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
