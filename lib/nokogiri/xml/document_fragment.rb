module Nokogiri
  module XML
    class DocumentFragment < Node
      def name
        '#document-fragment'
      end
    end
  end
end
