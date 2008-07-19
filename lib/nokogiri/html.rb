module Nokogiri
  module HTML
    class << self
      def parse(string, url = nil, encoding = nil, options = 32)
        Document.wrap(NokogiriLib.htmlReadMemory(
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
