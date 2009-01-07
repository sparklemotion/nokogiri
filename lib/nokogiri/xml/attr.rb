module Nokogiri
  module XML
    class Attr < Node
      def value
        children.first.to_s
      end
      alias :to_s :value
    end
  end
end
