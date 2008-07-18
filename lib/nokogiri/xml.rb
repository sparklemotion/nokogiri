module Nokogiri
  module XML
    class << self
      def parse(string, url = nil, encoding = nil, options = 1)
        Document.wrap(NokogiriLib.xmlReadMemory(
                                  string,
                                  string.length,
                                  url || 0,
                                  encoding || 0,
                                  options
                                 ))
      end
    end
  end
end
