module Nokogiri
  module XML
    class XPath
      def method_missing(method, *args, &block)
        node_set.send(method, *args, &block)
      end
    end
  end
end
