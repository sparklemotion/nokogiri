require 'nokogiri/syntax_error'
module Nokogiri
  module XML
    class XPath
      class SyntaxError < ::Nokogiri::SyntaxError
      end
    end
  end
end
