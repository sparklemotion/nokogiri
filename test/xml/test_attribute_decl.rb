require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestAttributeDecl < Nokogiri::TestCase
      def setup
        super
        @xml = Nokogiri::XML(File.read(XML_FILE), XML_FILE)
        @attr_decl = @xml.xpath('//gender')[2].child.children[3]
      end

      def test_type
        assert_equal 16, @attr_decl.type
      end

      def test_class
        assert_instance_of Nokogiri::XML::AttributeDeclaration, @attr_decl
      end

      def test_attributes
        assert_equal [], @attr_decl.attributes
      end
    end
  end
end

