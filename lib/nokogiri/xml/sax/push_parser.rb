module Nokogiri
  module XML
    module SAX
      class PushParser
        attr_accessor :document

        def initialize(doc = XML::SAX::Document.new, file_name = nil)
          @document = doc
          @sax_parser = XML::SAX::Parser.new(doc)

          ## Create our push parser context
          initialize_native(@sax_parser, file_name)
        end
      end
    end
  end
end
