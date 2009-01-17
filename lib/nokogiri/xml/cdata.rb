module Nokogiri
  module XML
    class CDATA < Text
      def name
        '#cdata-section'
      end
    end
  end
end
