module Nokogiri
  module XML
    class NodeSet
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
