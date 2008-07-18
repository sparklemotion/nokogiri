module Nokogiri
  module HTML
    class << self
      def parse(string, url = nil, encoding = nil, options = 32)
        Document.wrap(NokogiriLib.htmlReadMemory(
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
