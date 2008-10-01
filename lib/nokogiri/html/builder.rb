module Nokogiri
  module HTML
    class Builder < XML::Builder
      def to_html
        @doc.to_html
      end
    end
  end
end
