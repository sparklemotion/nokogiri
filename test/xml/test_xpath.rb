require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestXPath < Nokogiri::TestCase
      def setup
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)

        @handler = Class.new(XPathHandler) {
          attr_reader :things

          def initialize
            @things = []
          end

          def thing string
            @things << string
          end
        }.new
      end

      def test_custom_xpath_function_gets_strings
        set = @xml.xpath('//employee')
        @xml.xpath('//employee[thing("asdf")]', @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal(['asdf'] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_true_booleans
        set = @xml.xpath('//employee')
        @xml.xpath('//employee[thing(true())]', @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal([true] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_false_booleans
        set = @xml.xpath('//employee')
        @xml.xpath('//employee[thing(false())]', @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal([false] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_numbers
        set = @xml.xpath('//employee')
        @xml.xpath('//employee[thing(10)]', @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal([10] * set.length, @handler.things)
      end
    end
  end
end
