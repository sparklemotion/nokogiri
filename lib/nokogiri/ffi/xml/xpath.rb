module Nokogiri
  module XML
    class XPath
      
      attr_accessor :cstruct # :nodoc:

      def node_set # :nodoc:
        ptr = cstruct[:nodesetval] if cstruct[:nodesetval]
        ptr = LibXML.xmlXPathNodeSetCreate(nil) if ptr.null?

        set = XML::NodeSet.new(@document)
        set.cstruct = LibXML::XmlNodeSet.new(ptr)
        set.document = @document
        set
      end

    end
  end
end
