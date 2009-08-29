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
        assert_instance_of Nokogiri::XML::AttributeDecl, @attr_decl
      end

      def test_attributes
        assert_raise NoMethodError do
          @attr_decl.attributes
        end
      end

      def test_namespace
        assert_raise NoMethodError do
          @attr_decl.namespace
        end
      end

      def test_namespace_definitions
        assert_raise NoMethodError do
          @attr_decl.namespace_definitions
        end
      end

      def test_line
        assert_raise NoMethodError do
          @attr_decl.line
        end
      end

      def test_attribute_type
        assert_equal 1, @attr_decl.attribute_type
      end
    end
  end
end

