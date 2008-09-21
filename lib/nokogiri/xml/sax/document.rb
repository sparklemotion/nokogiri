module Nokogiri
  module XML
    module SAX
      class Document
        def internal_subset name, external_id, system_id
        end

        def standalone?
          true
        end

        def internal_subset?
          false
        end

        def external_subset?
          false
        end

        def start_element name, attrs = []
        end
      end
    end
  end
end
