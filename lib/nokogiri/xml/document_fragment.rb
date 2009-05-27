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

      alias :to_s       :inner_html
      alias :to_html    :inner_html
      alias :to_xml     :inner_html
      alias :serialize  :inner_html

      class << self
        ####
        # Create a Nokogiri::XML::DocumentFragment from +tags+
        def parse tags
          XML::DocumentFragment.new(XML::Document.new, tags)
        end
      end

    end
  end
end
