module Nokogiri
  module XML
    class Attr < Node
      def value
        content
      end
      alias :to_s :value

      def content= value
        self.value = value
      end
    end
  end
end
