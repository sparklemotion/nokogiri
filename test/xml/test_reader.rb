require "helper"

module Nokogiri
  module XML
    class TestReader < Nokogiri::TestCase
      def test_nonexistent_attribute
        require 'nokogiri'
        reader = Nokogiri::XML::Reader("<root xmlns='bob'><el attr='fred' /></root>")
        reader.read
        reader.read
        assert_equal reader.attribute('other'), nil
      end
    end
  end
end
