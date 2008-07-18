module Nokogiri
  class Node
    TYPE = ['PISPPPPPPPP',
      :private, :type, :name, :children, :last, :parent, :next, :prev, :doc, :ns, :content]
    def initialize(ptr)
      @ptr = ptr
      @ptr.struct!(*TYPE)
    end

    def name; @ptr[:name].to_s; end
    def child; Node.new(@ptr[:children]); end
    def next; Node.new(@ptr[:next]); end
    def content; @ptr[:content].to_s; end

    def [](property)
      property = NokogiriLib.xmlGetProp(
        @ptr,
        NokogiriLib.xmlCharStrdup(property.to_s)
      )
      property && property.to_s
    end

    def blank?
      1 == NokogiriLib.xmlIsBlankNode(@ptr)
    end
  end
end
