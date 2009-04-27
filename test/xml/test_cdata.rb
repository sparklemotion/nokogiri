require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestCDATA < Nokogiri::TestCase
      def setup
        super
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
      end

      def test_cdata_node
        name = @xml.xpath('//employee[2]/name').first
        assert cdata = name.children[1]
        assert cdata.cdata?
        assert_equal '#cdata-section', cdata.name
      end

      def test_new
        node = CDATA.new(@xml, "foo")
        assert_equal "foo", node.content

        node = CDATA.new(@xml.root, "foo")
        assert_equal "foo", node.content
      end

      def test_new_with_nil
        node = CDATA.new(@xml, nil)
        assert_equal nil, node.content
      end

      def test_lots_of_new_cdata
        100.times {
          node = CDATA.new(@xml, "asdfasdf")
        }
      end
    end
  end
end
