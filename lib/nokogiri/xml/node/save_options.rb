module Nokogiri
  module XML
    class Node
      ###
      # Save options for serializing nodes
      class SaveOptions
        FORMAT          = 1  # Format serialized xml
        NO_DECLARATION  = 2  # Do not include delcarations
        NO_EMPTY_TAGS   = 4
        NO_XHTML        = 8
        AS_XHTML        = 16
        AS_XML          = 32
        AS_HTML         = 64

        attr_reader :options
        def initialize options; @options = options; end
        %w{
          format no_declaration no_empty_tags no_xhtml as_xhtml as_html as_xml
        }.each do |type|
          define_method(type.to_sym) do
            @options |= self.class.const_get(type.upcase.to_sym)
            self
          end
        end
      end
    end
  end
end
