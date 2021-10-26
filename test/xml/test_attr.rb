# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestAttr < Nokogiri::TestCase
      def test_new
        100.times do
          doc = Nokogiri::XML::Document.new
          assert(doc)
          assert(Nokogiri::XML::Attr.new(doc, "foo"))
        end
      end

      def test_new_raises_argerror_on_nondocument
        document = Nokogiri::XML("<root><foo/></root>")
        assert_raises(ArgumentError) do
          Nokogiri::XML::Attr.new(document.at_css("foo"), "bar")
        end
      end

      def test_content=
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        address = xml.xpath("//address")[3]
        street = address.attributes["street"]
        street.content = "Y&ent1;"
        assert_equal("Y&ent1;", street.value)
      end

      #
      #  note that the set of tests around set_value include
      #  assertions on the serialized format. this is intentional.
      #
      def test_set_value_with_entity_string_in_xml_file
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        address = xml.xpath("//address")[3]
        street = address.attributes["street"]
        street.value = "Y&ent1;"
        assert_equal("Y&ent1;", street.value)
        assert_includes(%{ street="Y&amp;ent1;"}, street.to_xml)
      end

      def test_set_value_with_entity_string_in_html_file
        html = Nokogiri::HTML("<html><body><div foo='asdf'>")
        foo = html.at_css("div").attributes["foo"]
        foo.value = "Y&ent1;"
        assert_equal("Y&ent1;", foo.value)
        assert_includes(%{ foo="Y&amp;ent1;"}, foo.to_html)
      end

      def test_set_value_with_blank_string_in_html_file
        html = Nokogiri::HTML("<html><body><div foo='asdf'>")
        foo = html.at_css("div").attributes["foo"]
        foo.value = ""
        assert_equal("", foo.value)
        assert_includes(%{ foo=""}, foo.to_html)
      end

      def test_set_value_with_nil_in_html_file
        html = Nokogiri::HTML("<html><body><div foo='asdf'>")
        foo = html.at_css("div").attributes["foo"]
        foo.value = nil
        assert_equal("", foo.value) # this may be surprising to people, see xmlGetPropNodeValueInternal
        if Nokogiri.uses_libxml?
          assert_includes(%{ foo}, foo.to_html) # libxml2 still emits a boolean attribute at serialize-time
        else
          assert_includes(%{ foo=""}, foo.to_html) # jruby does not
        end
      end

      def test_set_value_of_boolean_attr_with_blank_string_in_html_file
        html = Nokogiri::HTML("<html><body><div disabled='disabled'>")
        disabled = html.at_css("div").attributes["disabled"]
        disabled.value = ""
        assert_equal("", disabled.value)
        assert_includes(%{ disabled}, disabled.to_html) # we still emit a boolean attribute at serialize-time!
      end

      def test_set_value_of_boolean_attr_with_nil_in_html_file
        html = Nokogiri::HTML("<html><body><div disabled='disabled'>")
        disabled = html.at_css("div").attributes["disabled"]
        disabled.value = nil
        assert_equal("", disabled.value) # this may be surprising to people, see xmlGetPropNodeValueInternal
        assert_includes(%{ disabled}, disabled.to_html) # but we emit a boolean attribute at serialize-time
      end

      def test_unlink # aliased as :remove
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        address = xml.xpath("/staff/employee/address").first
        assert_equal("Yes", address["domestic"])

        attr = address.attribute_nodes.first
        return_val = attr.unlink
        assert_nil(address["domestic"])
        assert_equal(attr, return_val)
      end

      def test_parsing_attribute_namespace
        doc = Nokogiri::XML(<<~EOXML)
          <root xmlns='http://google.com/' xmlns:f='http://flavorjon.es/'>
            <div f:myattr='foo'></div>
          </root>
        EOXML

        node = doc.at_css("div")
        attr = node.attributes["myattr"]
        assert_equal("http://flavorjon.es/", attr.namespace.href)
      end

      def test_setting_attribute_namespace
        doc = Nokogiri::XML(<<~EOXML)
          <root xmlns='http://google.com/' xmlns:f='http://flavorjon.es/'>
            <div f:myattr='foo'></div>
          </root>
        EOXML

        node = doc.at_css("div")
        attr = node.attributes["myattr"]
        attr.add_namespace("fizzle", "http://fizzle.com/")
        assert_equal("http://fizzle.com/", attr.namespace.href)
      end
    end
  end
end
