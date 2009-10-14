require "helper"

module Nokogiri
  module XML
    class TestSyntaxError < Nokogiri::TestCase
      def test_new
        error = Nokogiri::XML::SyntaxError.new 'hello'
        assert_equal 'hello', error.message
      end

      def test_exception
        error = Nokogiri::XML::SyntaxError.new 'hello'
        dup = error.exception 'world'
        assert_equal 'hello', dup.message
        assert_not_equal error.message.object_id, dup.message.object_id
      end

      def test_initialize_copy
        error = Nokogiri::XML::SyntaxError.new 'hello'
        dup = error.dup
        assert_equal 'hello', dup.message
        assert_not_equal error.object_id, dup.object_id
        assert_not_equal error.message.object_id, dup.message.object_id
      end
    end
  end
end
