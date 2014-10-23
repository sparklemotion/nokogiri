require "helper"

module Nokogiri
  module XML
    class TestSyntaxError < Nokogiri::TestCase
      def test_new
        error = Nokogiri::XML::SyntaxError.new 'hello'
        assert_equal 'hello', error.message
      end

      def test_pushing_to_non_array
        reader = Nokogiri::XML::Reader(StringIO.new('>>>'))
        assert_raises(SyntaxError) {
          reader.read
        }
        assert_equal [SyntaxError], reader.errors.map(&:class)
      end

      def test_pushing_to_array
        reader = Nokogiri::XML::Reader(StringIO.new('>>>'))
        def reader.errors
          1
        end
        assert_raises(TypeError) {
          reader.read
        }
      end unless Nokogiri.jruby? # which does not internally call `errors`
    end
  end
end
