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

      def to_s
        children.to_s
      end

      def to_html *args
        children.to_html(*args)
      end

      def to_xhtml *args
        children.to_xhtml(*args)
      end

      def to_xml *args
        children.to_xml(*args)
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
