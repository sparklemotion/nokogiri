# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestAttr < Nokogiri::TestCase
      def test_new_raises_argerror_on_nondocument
        document = Nokogiri::XML("<root><foo/></root>")

        assert_raises(ArgumentError) do
          Nokogiri::XML::Attr.new(document.at_css("foo"), "bar")
        end
      end

      def test_value_set_on_uninitialized_attr_raises_without_crashing
        attr = Nokogiri::XML::Attr.allocate

        refute_valgrind_errors(yield_on_jruby: true) do
          assert_raises(RuntimeError) { attr.value = "x" }
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
        assert_equal(%{street="Y&amp;ent1;"}, street.to_xml.strip)
      end

      def test_set_value_returns_assigned_value
        attr = Nokogiri::XML.parse("<root foo='bar'/>").root.attribute("foo")

        assert_equal("new value", attr.public_send(:value=, "new value"))
        assert_nil(attr.public_send(:value=, nil))
      end

      def test_set_value_with_entity_string_in_html_file
        html = Nokogiri::HTML("<html><body><div foo='asdf'>")
        foo = html.at_css("div").attributes["foo"]
        foo.value = "Y&ent1;"

        assert_equal("Y&ent1;", foo.value)
        assert_equal(%{foo="Y&amp;ent1;"}, foo.to_html.strip)
      end

      def test_set_value_with_blank_string_in_html_file
        html = Nokogiri::HTML("<html><body><div foo='asdf'>")
        foo = html.at_css("div").attributes["foo"]
        foo.value = ""

        assert_equal("", foo.value)
        assert_equal(%{foo=""}, foo.to_html.strip)
      end

      def test_set_value_with_nil_in_html_file
        html = Nokogiri::HTML("<html><body><div foo='asdf'>")
        foo = html.at_css("div").attributes["foo"]
        foo.value = nil

        # this may be surprising to people, see xmlGetPropNodeValueInternal
        assert_equal("", foo.value)
        if Nokogiri.uses_libxml?
          # libxml2 still emits a boolean attribute at serialize-time
          assert_equal(%{foo}, foo.to_html.strip)
        else
          # jruby does not
          assert_equal(%{foo=""}, foo.to_html.strip)
        end
      end

      def test_set_value_of_boolean_attr_with_blank_string_in_html_file
        html = Nokogiri::HTML("<html><body><div disabled='disabled'>")
        disabled = html.at_css("div").attributes["disabled"]
        disabled.value = ""

        assert_equal("", disabled.value)
        # we still emit a boolean attribute at serialize-time!
        assert_equal(%{disabled}, disabled.to_html.strip)
      end

      def test_set_value_of_boolean_attr_with_nil_in_html_file
        html = Nokogiri::HTML("<html><body><div disabled='disabled'>")
        disabled = html.at_css("div").attributes["disabled"]
        disabled.value = nil

        # this may be surprising to people, see xmlGetPropNodeValueInternal
        assert_equal("", disabled.value)
        # but we emit a boolean attribute at serialize-time
        assert_equal(%{disabled}, disabled.to_html.strip)
      end

      def test_set_value_does_not_pin_unwrapped_children
        skip("memory-safety test specific to libxml2") unless Nokogiri.uses_libxml?

        doc = Nokogiri::XML.parse("<root foo='bar'/>")
        attr = doc.root.attribute("foo")
        node_cache = doc.instance_variable_get(:@node_cache)
        node_cache_size = node_cache.length

        10.times do |i|
          attr.value = i.to_s
        end

        assert_equal(node_cache_size, node_cache.length)
        assert_equal("9", attr.value)
      end

      def test_set_value_does_not_free_wrapped_children
        skip("memory-safety test specific to libxml2") unless Nokogiri.uses_libxml?

        attr = Nokogiri::XML.parse("<root foo='bar'/>").root.attribute("foo")
        child = attr.child # wrap the XML::Text node

        refute_valgrind_errors do
          attr.value = "new value"
        end

        assert_equal "bar", child.to_s
      end

      def test_set_value_preserves_all_wrapped_children
        skip("memory-safety test specific to libxml2") unless Nokogiri.uses_libxml?

        doc = Nokogiri::XML.parse(<<~XML)
          <!DOCTYPE root [<!ENTITY e "E">]>
          <root foo="a&e;b"/>
        XML
        attr = doc.root.attribute("foo")
        old_children = attr.children.to_a

        assert_equal(["a", "&e;", "b"], old_children.map(&:to_s))

        refute_valgrind_errors do
          attr.value = "new value"
          GC.start(full_mark: true)
        end

        assert_equal(["a", "&e;", "b"], old_children.map(&:to_s))
        assert(old_children.all? { |child| child.parent.nil? })
        assert_equal("new value", attr.value)
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
