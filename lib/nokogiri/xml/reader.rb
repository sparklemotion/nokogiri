module Nokogiri
  module XML
    class Reader
      include Enumerable

      def each(&block)
        while node = self.read
          block.call(node)
        end
      end
      private :initialize
    end
  end
end
