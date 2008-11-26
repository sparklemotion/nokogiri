require 'nokogiri'

module Nokogiri
  module Hpricot
    STag = String
    Elem = XML::Node
    NamedCharacters = Nokogiri::HTML::NamedCharacters
    class << self
      def parse(*args)
        doc = Nokogiri.parse(*args)
        add_decorators(doc)
      end

      def XML(string)
        doc = Nokogiri::XML.parse(string)
        add_decorators(doc)
      end

      def HTML(string)
        doc = Nokogiri::HTML.parse(string)
        add_decorators(doc)
      end

      def make string
        doc = XML::Document.new
        ns = XML::NodeSet.new(doc)
        ns << XML::Text.new(string, doc)
        ns
      end

      def add_decorators(doc)
        doc.decorators(XML::Node) << Decorators::Hpricot::Node
        doc.decorators(XML::NodeSet) << Decorators::Hpricot::NodeSet
        doc.decorate!
        doc
      end
    end
  end
  
  class << self
    def Hpricot(*args, &block)
      if block_given?
        builder = Nokogiri::HTML::Builder.new(&block)
        Nokogiri::Hpricot.add_decorators(builder.doc)
      else
        doc = Nokogiri.parse(*args)
        Nokogiri::Hpricot.add_decorators(doc)
      end
    end
  end
end
