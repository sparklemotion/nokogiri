module Nokogiri
  module HTML
    class Document < XML::Document
      def to_html
        serialize
      end
    end
  end
end
