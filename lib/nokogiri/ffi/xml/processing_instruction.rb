module Nokogiri
  module XML
    class ProcessingInstruction < Node

      attr_accessor :cstruct

      def self.new(document, name, content)
        node_ptr = LibXML.xmlNewDocPI(document.cstruct, name.to_s, content.to_s)

        node_cstruct = LibXML::XmlNode.new(node_ptr)
        node_cstruct[:doc] = document.cstruct[:doc]
        LibXML.xmlXPathNodeSetAdd(node_cstruct.document.node_set, node_cstruct)

        node = Node.wrap(node_cstruct)
        yield node if block_given?
        node
      end

    end
  end
end
