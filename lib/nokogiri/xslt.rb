require 'nokogiri/xslt/stylesheet'

module Nokogiri
  module XSLT
    class << self
      def parse(string)
        Stylesheet.parse_stylesheet_doc(XML.parse(string))
      end
    end
  end
end
