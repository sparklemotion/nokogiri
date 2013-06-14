require "helper"

module Nokogiri
  module XML
    class TestSyntaxError < Nokogiri::TestCase
      def test_new
        error = Nokogiri::XML::SyntaxError.new 'hello'
        assert_equal 'hello', error.message
      end

      def test_node_attribute_on_invalid_node
        xsd = Nokogiri::XML::Schema(File.read(PO_SCHEMA_FILE))
        read_doc = Nokogiri::XML(File.read(PO_XML_FILE).gsub(/<city>[^<]*<\/city>/, ''))

        assert errors = xsd.validate(read_doc)
        errors.each_index { |i| assert_equal read_doc.css("state")[i], errors[i].node }
      end

      def test_no_node_attribute_on_malformed
        error = assert_raise Nokogiri::XML::SyntaxError do
          Nokogiri::XML('<foo><bar></foo>', nil, nil, 0)
        end
        assert_nil error.node
      end
    end
  end
end
