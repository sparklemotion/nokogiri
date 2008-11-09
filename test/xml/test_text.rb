require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestText < Nokogiri::TestCase
      def test_new
        node = Text.new('hello world', Document.new)
        assert node
        assert_equal('hello world', node.content)
      end
    end
  end
end
