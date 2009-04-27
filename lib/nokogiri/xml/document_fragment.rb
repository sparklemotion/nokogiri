module Nokogiri
  module XML
    class DocumentFragment < Nokogiri::XML::Node
      ###
      # return the name for DocumentFragment
      def name
        '#document-fragment'
      end
    end
  end
end
