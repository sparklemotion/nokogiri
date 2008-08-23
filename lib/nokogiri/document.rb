module Nokogiri
  # Wraps xmlDocPtr
  class Document < Node
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
  end
end
