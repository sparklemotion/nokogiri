require 'nokogiri/xslt/stylesheet'

module Nokogiri
  module XSLT
    class << self
      def parse(string)
        Stylesheet.wrap(DL::XSLT.xsltParseStylesheetDoc(XML.parse(string)))
      end
    end
  end
end
