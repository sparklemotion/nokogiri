module Nokogiri
  module XML
    class DocumentFragment < Nokogiri::XML::Node
      def initialize document
      end

      ###
      # return the name for DocumentFragment
      def name
        '#document-fragment'
      end

      alias :to_s     :inner_html
      alias :to_html  :inner_html
    end
  end
end
