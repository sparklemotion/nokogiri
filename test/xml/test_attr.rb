require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestAttr < Nokogiri::TestCase
      def test_unlink
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        address = xml.xpath('/staff/employee/address').first
        assert_equal 'Yes', address['domestic']
        address.attribute_nodes.first.unlink
        assert_nil address['domestic']
      end
    end
  end
end
