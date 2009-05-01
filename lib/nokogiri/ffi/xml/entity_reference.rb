module Nokogiri
  module XML
    class EntityReference < Node

      def self.new(document, name, &block)
        node_ptr = LibXML.xmlNewReference(document.cstruct, name)

        node_cstruct = LibXML::XmlNode.new(node_ptr)
        node_cstruct[:doc] = document.cstruct[:doc]

        LibXML.xmlXPathNodeSetAdd(node_cstruct.document.node_set, node_cstruct);

        node = Node.wrap(node_cstruct)

        yield node if block_given?

        node
      end

    end
  end
end

