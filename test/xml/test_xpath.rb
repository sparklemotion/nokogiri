require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestXPath < Nokogiri::TestCase
      def setup
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)

        @handler = Class.new(XPathHandler) {
          attr_reader :strings, :booleans

          def initialize
            @strings = []
            @booleans = []
          end

          def string_func string
            @strings << string
          end

          def boolean_func bool
            @booleans << bool
          end
        }.new
      end

      def test_custom_xpath_function_gets_strings
        set = @xml.xpath('//employee')
        @xml.xpath('//employee[string_func("asdf")]', @handler)
        assert_equal(set.length, @handler.strings.length)
        assert_equal(['asdf'] * set.length, @handler.strings)
      end

      def test_custom_xpath_gets_true_booleans
        set = @xml.xpath('//employee')
        @xml.xpath('//employee[boolean_func(true())]', @handler)
        assert_equal(set.length, @handler.booleans.length)
        assert_equal([true] * set.length, @handler.booleans)
      end

      def test_custom_xpath_gets_false_booleans
        set = @xml.xpath('//employee')
        @xml.xpath('//employee[boolean_func(false())]', @handler)
        assert_equal(set.length, @handler.booleans.length)
        assert_equal([false] * set.length, @handler.booleans)
      end
    end
  end
end
