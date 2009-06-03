module Nokogiri
  module XML
    class Namespace # :nodoc:

      attr_accessor :cstruct # :nodoc:
      attr_accessor :document # :nodoc:

      def prefix  # :nodoc:
        cstruct[:prefix].nil? ? nil : cstruct[:prefix] # TODO: encoding?
      end

      def href # :nodoc:
        cstruct[:href].nil? ? nil : cstruct[:href] # TODO: encoding?
      end

      class << self
        def wrap(document, node_struct) # :nodoc:
          if node_struct.is_a?(FFI::Pointer)
            # cast native pointers up into a node cstruct
            return nil if node_struct.null?
            node_struct = LibXML::XmlNs.new(node_struct) 
          end

          ruby_node = node_struct.ruby_node
          return ruby_node unless ruby_node.nil?

          ns = Nokogiri::XML::Namespace.allocate
          ns.document = document.ruby_doc
          ns.cstruct = node_struct
          
          ns.cstruct.ruby_node = ns

          cache = ns.document.instance_variable_get(:@node_cache)
          cache << ns

          ns
        end
      end

    end
  end
end
