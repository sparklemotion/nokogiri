require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestAttr < Nokogiri::TestCase
      def test_new
        100.times {
          doc = Nokogiri::XML::Document.new
          attribute = Nokogiri::XML::Attr.new(doc, 'foo')
        }
      end

      def test_content=
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        address = xml.xpath('//address')[3]
        street = address.attributes['street']
        street.content = "Y&ent1;"
        assert_equal "Y&ent1;", street.value
      end

      def test_value=
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        address = xml.xpath('//address')[3]
        street = address.attributes['street']
        street.value = "Y&ent1;"
        assert_equal "Y&ent1;", street.value
      end

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
