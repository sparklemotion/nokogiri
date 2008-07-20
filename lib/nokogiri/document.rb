module Nokogiri
  # Wraps xmlDocPtr
  class Document < Node
    def initialize(type = :xml)
      yield self if block_given?
      unless self.ptr
        self.ptr =
          case type
          when :xml
            NokogiriLib.xmlNewDoc(NokogiriLib.xmlCharStrdup('1.0'))
          when :html
            NokogiriLib.htmlNewDoc(nil, nil)
          end
      end
      self.ptr.struct!('PISPPPPPP', :private, :type, :name, :children, :last, :parent, :next, :prev, :doc)
    end
  end
end
