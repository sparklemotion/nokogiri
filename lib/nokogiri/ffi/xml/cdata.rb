module Nokogiri
  module XML
    class CDATA < Text
      
      def self.new(document, content, &block)
        length = content.nil? ? 0 : content.length
        node_ptr = LibXML.xmlNewCDataBlock(document.cstruct[:doc], content, length)

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
