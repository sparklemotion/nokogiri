module Nokogiri
  # Wraps xmlDocPtr
  class Document < Node
    def initialize(type = :xml)
      yield self if block_given?
      unless self.ptr
        root =
          case type
          when :xml
            NokogiriLib.xmlNewDoc(NokogiriLib.xmlCharStrdup('1.0'))
          when :html
            NokogiriLib.htmlNewDoc(nil, nil)
          end
        self.ptr = NokogiriLib::Node.new(root)
      end
    end
  end
end
