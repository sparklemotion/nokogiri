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
      end
    end
  end
end
