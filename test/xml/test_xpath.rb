require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestXPath < Nokogiri::TestCase
      def setup
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
      end

      def test_custom_xpath_function_gets_strings
        handler = Class.new(XPathHandler) {
          attr_reader :strings

          def initialize
            @strings = []
          end

          def awesome string
            @strings << string
          end
        }.new

        set = @xml.xpath('//employee')
        @xml.xpath('//employee[awesome("asdf")]', handler)
        assert_equal(set.length, handler.strings.length)
      end
    end
  end
end
