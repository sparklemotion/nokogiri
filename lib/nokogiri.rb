require 'dl/import'
require 'nokogiri_lib'

class Nokogiri
  VERSION = '1.0.0'

  class << self
    def parse(string, url = nil, encoding = nil, options = 1)
      doc = NokogiriLib.htmlReadMemory(
        string,
        string.length,
        url || 0,
        encoding || 0,
        options
      )
      Document.new(doc)
    end
  end

  class Document
    def initialize(ptr)
      @ptr = ptr
    end

    def root
      Node.new(NokogiriLib::Tree.xmlDocGetRootElement(@ptr))
    end
  end

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
      property = NokogiriLib::Node.xmlGetProp(
        @ptr,
        NokogiriLib.xmlCharStrdup(property.to_s)
      )
      property && property.to_s
    end

    def blank?
      1 == NokogiriLib::Node.xmlIsBlankNode(@ptr)
    end
  end
end
