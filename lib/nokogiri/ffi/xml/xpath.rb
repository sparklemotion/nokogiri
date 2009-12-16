module Nokogiri
  module XML
    class XPath
      
      attr_accessor :cstruct # :nodoc:

      def node_set # :nodoc:
        ptr = cstruct[:nodesetval] if cstruct[:nodesetval]
        ptr = LibXML.xmlXPathNodeSetCreate(nil) if ptr.null?

        NodeSet.wrap(ptr, @document)
      end

    end
  end
end
