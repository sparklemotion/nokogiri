module Nokogiri
  module XML
    class Comment < Node
      
      def self.new(document, content, &block) # :nodoc:
        node_ptr = LibXML.xmlNewDocComment(document.cstruct, content)
        node_cstruct = LibXML::XmlNode.new(node_ptr)
        node_cstruct.keep_reference_from_document!

        node = Node.wrap(node_ptr, self)
        yield node if block_given?
        node
      end

    end
  end
end
