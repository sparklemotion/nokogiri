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

      def initialize *args
        @decorators = nil
      end

      # The name of this document.  Always returns "document"
      def name
        'document'
      end

      # A reference to +self+
      def document
        self
      end

      # Get the list of decorators given +key+
      def decorators key
        @decorators ||= Hash.new
        @decorators[key] ||= []
      end

      ###
      # Validate this Document against it's DTD.  Returns a list of errors on
      # the document or +nil+ when there is no DTD.
      def validate
        return nil unless internal_subset
        internal_subset.validate self
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
      def decorate node
        return unless @decorators
        @decorators.each { |klass,list|
          next unless node.is_a?(klass)
          list.each { |moodule| node.extend(moodule) }
        }
      end

      alias :to_xml :serialize
      alias :clone :dup

      # Get the hash of namespaces on the root Nokogiri::XML::Node
      def namespaces
        root ? root.collect_namespaces : {}
      end

      ####
      # Create a Nokogiri::XML::DocumentFragment from +tags+
      def fragment tags
        DocumentFragment.new(self, tags)
      end

      undef_method :swap, :parent, :namespace, :default_namespace=
      undef_method :add_namespace_definition

      def add_child child
        if [Node::ELEMENT_NODE, Node::DOCUMENT_FRAG_NODE].include? child.type
          raise "Document already has a root node" if root
        end
        super
      end
      alias :<< :add_child

      class << self
        ###
        # Parse an XML file.  +thing+ may be a String, or any object that
        # responds to _read_ and _close_ such as an IO, or StringIO.
        # +url+ is resource where this document is located.  +encoding+ is the
        # encoding that should be used when processing the document. +options+
        # is a number that sets options in the parser, such as
        # Nokogiri::XML::ParseOptions::RECOVER.  See the constants in
        # Nokogiri::XML::ParseOptions.
        def parse string_or_io, url = nil, encoding = nil, options = ParseOptions::DEFAULT_XML, &block

          options = Nokogiri::XML::ParseOptions.new(options) if Fixnum === options
          # Give the options to the user
          yield options if block_given?

          if string_or_io.respond_to?(:read)
            url ||= string_or_io.respond_to?(:path) ? string_or_io.path : nil
            return self.read_io(string_or_io, url, encoding, options.to_i)
          end

          # read_memory pukes on empty docs
          return self.new if string_or_io.nil? or string_or_io.empty?

          self.read_memory(string_or_io, url, encoding, options.to_i)
        end
      end

    end
  end
end
