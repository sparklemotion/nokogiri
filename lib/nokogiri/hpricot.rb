require 'nokogiri'

module Nokogiri
  module Hpricot
    # STag compatibility proxy
    STag = String
    # Elem compatibility proxy
    Elem = XML::Node
    # NamedCharacters compatibility proxy
    NamedCharacters = Nokogiri::HTML::NamedCharacters
    class << self
      # parse proxy
      def parse(*args)
        doc = Nokogiri.parse(*args)
        add_decorators(doc)
      end

      # XML proxy
      def XML(string)
        doc = Nokogiri::XML::Document.parse(string)
        add_decorators(doc)
      end

      # HTML proxy
      def HTML(string)
        doc = Nokogiri::HTML::Document.parse(string)
        add_decorators(doc)
      end

      # make proxy
      def make string
        doc = XML::Document.new
        ns = XML::NodeSet.new(doc)
        ns << XML::Text.new(string, doc)
        ns
      end

      # Add compatibility decorators
      def add_decorators(doc)
        doc.decorators(XML::Node) << Decorators::Hpricot::Node
        doc.decorators(XML::NodeSet) << Decorators::Hpricot::NodeSet
        doc.decorate!
        doc
      end
    end
  end

  class << self
    ###
    # Parse a document and apply the Hpricot decorators for Hpricot
    # compatibility mode.
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
