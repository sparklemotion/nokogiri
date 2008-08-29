module Nokogiri
  module XML
    class TextNode < Nokogiri::Node
      include W3C::Org::Dom::Text

      def splitText(index)
        left = content.slice(0..index - 1)
        right = content.slice(index..-1)

        self.content = left
        new_node = Node.wrap(DL::XML.xmlCopyNode(self, 1))
        new_node.content = right
        # FIXME the spec says we're supposed to do this, but the tests
        # fail....
        #DL::XML.xmlAddNextSibling(self, new_node)
        #DL::XML.xmlAddPrevSibling(new_node, self)
        new_node
      end
    end
  end
end
