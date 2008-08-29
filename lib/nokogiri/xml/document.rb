module Nokogiri
  module XML
    # Wraps xmlDocPtr
    class Document < Node
      include W3C::Org::Dom::Document

      def initialize(type = :xml)
        yield self if block_given?
        unless self.ptr
          root =
            case type
            when :xml
              DL::XML.xmlNewDoc(DL::XML.xmlCharStrdup('1.0'))
            when :html
              DL::XML.htmlNewDoc(nil, nil)
            end
          self.ptr = DL::XML::Node.new(root)
        end
      end

      alias :getDoctype :type
      def getElementsByTagName(name)
        search("//#{name}")
      end
    end
  end
end
