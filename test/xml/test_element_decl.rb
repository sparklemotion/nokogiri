require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestElementDecl < Nokogiri::TestCase
      def setup
        super
        @xml = Nokogiri::XML(File.read(XML_FILE), XML_FILE)
        @elem_decl = @xml.xpath('//gender')[2].child.children[2]
      end

      def test_type
        assert_equal 15, @elem_decl.type
      end

      def test_class
        assert_instance_of Nokogiri::XML::ElementDeclaration, @elem_decl
      end

      def test_attributes
        assert_equal ['width'], @elem_decl.attributes.keys
      end
    end
  end
end
