module Nokogiri
  module XML
    class << self
      def parse(string, url = nil, encoding = nil, options = 1)
        Document.wrap(NokogiriLib::XML.xmlReadMemory(
                                  string,
                                  string.length,
                                  NokogiriLib::XML.dl2? ? (url || 0) : url,
                                  NokogiriLib::XML.dl2? ? (encoding || 0) : encoding,
                                  options
                                 ))
      end
    end
  end
end
