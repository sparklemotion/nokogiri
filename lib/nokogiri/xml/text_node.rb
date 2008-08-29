module Nokogiri
  module XML
    class TextNode < Nokogiri::XML::Node
      include W3C::Org::Dom::Text

      def splitText(index)
        left = content.slice(0..index - 1)
        right = content.slice(index..-1)

        self.content = left
        new_node = Node.new(self.name)
        new_node.content = right
        DL::XML.xmlAddNextSibling(self, new_node)
        DL::XML.xmlAddPrevSibling(new_node, self)
        new_node
      end
    end
  end
end
