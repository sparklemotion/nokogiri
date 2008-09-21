module Nokogiri
  module XML
    module SAX
      class Parser
        attr_accessor :document
        def initialize(doc = SAX::Document.new)
          @document = doc
        end
      end
    end
  end
end
