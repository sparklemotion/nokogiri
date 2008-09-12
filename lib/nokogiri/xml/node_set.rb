module Nokogiri
  module XML
    class NodeSet
      include Enumerable

      def first
        self[0]
      end

      def last
        self[length - 1]
      end

      ###
      # Iterate over each node, yielding  to +block+
      def each(&block)
        x = 0
        while x < length
          yield self[x]
          x += 1
        end
      end
    end
  end
end
