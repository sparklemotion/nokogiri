module Nokogiri
  module XML
    class DocumentFragment < Nokogiri::XML::Node
      def initialize document, tags=nil
        if tags
          parser = if self.kind_of?(Nokogiri::HTML::DocumentFragment)
                     HTML::SAX::Parser.new(FragmentHandler.new(self, tags))
                   else
                     XML::SAX::Parser.new(FragmentHandler.new(self, tags))
                   end
          parser.parse(tags)
        end
      end

      ###
      # return the name for DocumentFragment
      def name
        '#document-fragment'
      end

      ###
      # Convert this DocumentFragment to a string
      def to_s
        children.to_s
      end

      ###
      # Convert this DocumentFragment to html
      # See Nokogiri::XML::NodeSet#to_html
      def to_html *args
        children.to_html(*args)
      end

      ###
      # Convert this DocumentFragment to xhtml
      # See Nokogiri::XML::NodeSet#to_xhtml
      def to_xhtml *args
        children.to_xhtml(*args)
      end

      ###
      # Convert this DocumentFragment to xml
      # See Nokogiri::XML::NodeSet#to_xml
      def to_xml *args
        children.to_xml(*args)
      end

      ###
      # Search this fragment.  See Nokogiri::XML::Node#css
      def css *args
        children.css(*args)
      end

      alias :serialize :to_s

      class << self
        ####
        # Create a Nokogiri::XML::DocumentFragment from +tags+
        def parse tags
          self.new(XML::Document.new, tags)
        end
      end

    end
  end
end
