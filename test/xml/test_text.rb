require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestText < Nokogiri::TestCase
      def test_inspect
        node = Text.new('hello world', Document.new)
        assert_equal "#<#{node.class.name}:#{sprintf("0x%x",node.object_id)} #{node.text.inspect} >", node.inspect
      end

      def test_new
        node = Text.new('hello world', Document.new)
        assert node
        assert_equal('hello world', node.content)
        assert_instance_of Nokogiri::XML::Text, node
      end

      def test_lots_of_text
        100.times { Text.new('hello world', Document.new) }
      end
    end
  end
end
