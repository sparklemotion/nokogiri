module Nokogiri
  module XML
    class Document < Node
      def to_xml
        serialize
      end
    end
  end
end
