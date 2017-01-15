require "helper"

module Nokogiri
  module XML
    class TestSyntaxError < Nokogiri::TestCase
      def test_new
        error = Nokogiri::XML::SyntaxError.new 'hello'
        assert_equal 'hello', error.message
      end

      def test_line_column
        bad_doc = Nokogiri::XML('test')
        error = bad_doc.errors.first
        assert_equal "Start tag expected, '<' not found, 1, 1", error.message
        assert_equal 1, error.line
        assert_equal 1, error.column
      end
    end
  end
end
