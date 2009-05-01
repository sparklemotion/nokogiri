module Nokogiri
  module XML
    class Comment < Node
      
      def self.new(document, content, &block)
        node_ptr = LibXML.xmlNewDocComment(document.cstruct, content)
        node_cstruct = LibXML::XmlNode.new(node_ptr)

        LibXML.xmlXPathNodeSetAdd(node_cstruct.document.node_set, node_cstruct);

        node = Node.wrap(node_ptr)
        
        yield node if block_given?

        node
      end

    end
  end
end
