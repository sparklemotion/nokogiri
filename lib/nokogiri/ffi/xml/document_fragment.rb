module Nokogiri
  module XML
    class DocumentFragment < Node

      def self.new(document, *rest) # :nodoc:
        node_ptr = LibXML.xmlNewDocFragment(document.cstruct)
        node_cstruct = LibXML::XmlNode.new(node_ptr)
        node_cstruct.keep_reference_from_document!

        node = Node.wrap(node_cstruct, self)

        if node.document.child && node.document.child.node_type == ELEMENT_NODE
          # TODO: node_type check should be ported into master, because of e.g. DTD nodes
          node.cstruct[:ns] = node.document.children.first.cstruct[:ns] 
        end

        node.send :initialize, document, *rest
        yield node if block_given?

        node
      end

    end
  end
end

