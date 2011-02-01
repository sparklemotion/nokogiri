module Nokogiri
  module XML
    class Node
      ###
      # Save options for serializing nodes
      #
      # Usage example:
      #   Nokogiri::XML::Builder.new { |xml|
      #   xml.foo {
      #     xml.bar {
      #       xml.baz 'quux'
      #     }
      #   }.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
      #

      class SaveOptions
        # Format serialized xml, e.g. with newlines
        FORMAT          = 1
        # Do not include declarations, e.g. <?xml version="1.0">
        NO_DECLARATION  = 2
        # Do not include empty tags
        NO_EMPTY_TAGS   = 4
        # Do not save XHTML
        NO_XHTML        = 8
        # Save as XHTML
        AS_XHTML        = 16
        # Save as XML
        AS_XML          = 32
        # Save as HTML
        AS_HTML         = 64

        # Integer representation of the SaveOptions
        attr_reader :options

        # Create a new SaveOptions object with +options+
        def initialize options = 0; @options = options; end

        constants.each do |constant|
          class_eval %{
            def #{constant.downcase}
              @options |= #{constant}
              self
            end

            def #{constant.downcase}?
              #{constant} & @options == #{constant}
            end
          }
        end

        alias :to_i :options
      end
    end
  end
end
