module Nokogiri
  module XML
    class << self
      def parse(string, url = nil, encoding = nil, options = 1)
        Document.wrap(NokogiriLib.xmlReadMemory(
                                  string,
                                  string.length,
                                  url,
                                  encoding,
                                  options
                                 ))
      end
    end
  end
end
