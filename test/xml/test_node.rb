require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestNode < Nokogiri::TestCase
      def test_new_node
        node = Nokogiri::XML::Node.new('form')
        assert_equal('form', node.name)
        assert_nil(node.document)
      end

      def test_content
        node = Nokogiri::XML::Node.new('form')
        assert_equal('', node.content)

        node.content = 'hello world!'
        assert_equal('hello world!', node.content)
      end
    end
  end
end
