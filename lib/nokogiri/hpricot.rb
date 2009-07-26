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
        warn <<-eomsg
Nokogiri::Hpricot.parse is deprecated and will be extracted to it's own gem
when Nokogiri 1.4.0 is released.  Please switch to Nokogiri(), or be prepared
to install the compatibility layer.
#{caller.first}
eomsg
        doc = Nokogiri.parse(*args)
        add_decorators(doc)
      end

      # XML proxy
      def XML(string)
        warn <<-eomsg
Nokogiri::Hpricot.parse is deprecated and will be extracted to it's own gem
when Nokogiri 1.4.0 is released.  Please switch to Nokogiri::XML(), or be
prepared to install the compatibility layer.
#{caller.first}
eomsg
        doc = Nokogiri::XML::Document.parse(string)
        add_decorators(doc)
      end

      # HTML proxy
      def HTML(string)
        warn <<-eomsg
Nokogiri::Hpricot.parse is deprecated and will be extracted to it's own gem
when Nokogiri 1.4.0 is released.  Please switch to Nokogiri::HTML(), or be
prepared to install the compatibility layer.
#{caller.first}
eomsg
        doc = Nokogiri::HTML::Document.parse(string)
        add_decorators(doc)
      end

      # make proxy
      def make string
        warn <<-eomsg
Nokogiri::Hpricot.parse is deprecated and will be extracted to it's own gem
when Nokogiri 1.4.0 is released.  Please switch to Nokogiri::HTML.make(), or be
prepared to install the compatibility layer.
#{caller.first}
eomsg
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
        warn <<-eomsg
Nokogiri::Hpricot.parse is deprecated and will be extracted to it's own gem
when Nokogiri 1.4.0 is released.  Please switch to Nokogiri(), or be
prepared to install the compatibility layer.
#{caller.first}
eomsg
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
