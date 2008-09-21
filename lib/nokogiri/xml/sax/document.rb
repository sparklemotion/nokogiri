module Nokogiri
  module XML
    module SAX
      class Document
        def internal_subset name, external_id, system_id
        end

        def standalone?
          true
        end

        def start_element name, attrs = []
        end
      end
    end
  end
end
