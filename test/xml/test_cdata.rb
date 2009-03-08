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
    end
  end
end
