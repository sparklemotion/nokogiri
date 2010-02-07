module Nokogiri
  module XML
    class DocumentFragment < Nokogiri::XML::Node
      def initialize document, tags = nil, ctx = document.root
        return self unless tags

        if document.html?
          HTML::SAX::Parser.new(FragmentHandler.new(self, tags)).parse(tags)
        else
          has_root = document.root

          unless ctx
            ctx = document.root = Nokogiri::XML::Element.new('div', document)
          end

          ctx.parse(tags.strip).each do |tag|
            tag.parent = self
          end

          document.root = nil unless has_root
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
        if children.any?
          children.css(*args)
        else
          NodeSet.new(document)
        end
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
