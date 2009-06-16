module Nokogiri
  module LibXML # :nodoc:
    module CommonNode # :nodoc:

      def document
        p = self[:doc]
        p.null? ? nil : LibXML::XmlDocumentCast.new(p)
      end

      def ruby_node
        self[:_private] != 0 ? ObjectSpace._id2ref(self[:_private]) : nil
      end

      def ruby_node=(object)
        self[:_private] = object.object_id
      end

      def keep_reference_from_document! # equivalent to NOKOGIRI_ROOT_NODE
        doc = self.document
        raise "no document to add reference to" unless doc
        LibXML.xmlXPathNodeSetAdd(doc.node_set, self)
      end
    end
  end
end

