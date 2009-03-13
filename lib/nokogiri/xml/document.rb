module Nokogiri
  module XML
    ####
    # Nokogiri::XML::Document is the main entry point for dealing with
    # XML documents.  The Document is created by parsing an XML document.
    # See Nokogiri.XML()
    #
    # For searching a Document, see Nokogiri::XML::Node#css and
    # Nokogiri::XML::Node#xpath
    class Document < Node
      # A list of Nokogiri::XML::SyntaxError found when parsing a document
      attr_accessor :errors

      # The name of this document.  Always returns "document"
      def name
        'document'
      end

      # A reference to +self+
      def document
        self
      end

      # Get the list of decorators given +key+
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

      def node_cache # :nodoc:
        @node_cache ||= {}
      end

      alias :to_xml :serialize
      alias :inner_html :serialize

      # Get the hash of namespaces on the root Nokogiri::XML::Node
      def namespaces
        root ? root.collect_namespaces : {}
      end

      undef_method :swap, :parent, :namespace
    end
  end
end
