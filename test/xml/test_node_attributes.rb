# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestNodeAttributes < Nokogiri::TestCase
      let(:simple_xml_with_namespaces) { <<~XML }
        <root xmlns:tlm='http://tenderlovemaking.com/'>
          <node tlm:foo='bar' foo='baz' />
          <next tlm:foo='baz' />
        </root>
      XML

      describe "#attribute" do
        it "returns an attribute that matches the local name" do
          doc = Nokogiri.XML(simple_xml_with_namespaces)
          node = doc.at_css("next")
          refute_nil(attr = node.attribute("foo"))

          # NOTE: that we don't make any claim over _which_ attribute should be returned.
          # this situation is ambiguous and we make no guarantees.
          assert_equal("foo", attr.name)
        end

        it "does not return an attribute that matches the full name" do
          doc = Nokogiri.XML(simple_xml_with_namespaces)
          node = doc.at_css("next")
          assert_nil(node.attribute("tlm:foo"))
        end
      end

      describe "#attribute_with_ns" do
        it "returns the attribute that matches the name and namespace" do
          doc = Nokogiri.XML(simple_xml_with_namespaces)
          node = doc.at_css("node")

          refute_nil(attr = node.attribute_with_ns("foo", "http://tenderlovemaking.com/"))
          assert_equal("bar", attr.value)
        end

        it "returns the attribute that matches the name and nil namespace" do
          doc = Nokogiri.XML(simple_xml_with_namespaces)
          node = doc.at_css("node")

          refute_nil(attr = node.attribute_with_ns("foo", nil))
          assert_equal("baz", attr.value)
        end

        it "does not return a attribute that matches name but not namespace" do
          doc = Nokogiri.XML(simple_xml_with_namespaces)
          node = doc.at_css("node")

          assert_nil(node.attribute_with_ns("foo", "http://nokogiri.org/"))
        end

        it "does not return a attribute that matches namespace but not name" do
          doc = Nokogiri.XML(simple_xml_with_namespaces)
          node = doc.at_css("node")

          assert_nil(node.attribute_with_ns("not-present", "http://tenderlovemaking.com/"))
        end
      end

      describe "#set_attribute" do
        it "round trips" do
          doc = Nokogiri.XML(simple_xml_with_namespaces)
          node = doc.at_css("node")
          node["xxx"] = "yyy"
          refute_nil(node.attribute("xxx"))
          assert_equal("yyy", node.attribute("xxx").value)
        end
      end

      def test_prefixed_attributes
        doc = Nokogiri::XML("<root xml:lang='en-GB' />")

        node = doc.root

        assert_equal("en-GB", node["xml:lang"])
        assert_equal("en-GB", node.attributes["lang"].value)
        assert_nil(node["lang"])
      end

      def test_unknown_namespace_prefix_should_not_be_removed
        doc = Nokogiri::XML("")
        elem = doc.create_element("foo", "bar:attr" => "something")
        assert_equal("bar:attr", elem.attribute_nodes.first.name)
      end

      def test_set_prefixed_attributes
        doc = Nokogiri::XML(%{<root xmlns:foo="x"/>})

        node = doc.root

        node["xml:lang"] = "en-GB"
        node["foo:bar"]  = "bazz"

        assert_equal("en-GB", node["xml:lang"])
        assert_equal("en-GB", node.attributes["lang"].value)
        assert_nil(node["lang"])
        assert_equal("http://www.w3.org/XML/1998/namespace", node.attributes["lang"].namespace.href)

        assert_equal("bazz", node["foo:bar"])
        assert_equal("bazz", node.attributes["bar"].value)
        assert_nil(node["bar"])
        assert_equal("x", node.attributes["bar"].namespace.href)
      end

      def test_append_child_namespace_definitions_prefixed_attributes
        doc = Nokogiri::XML("<root/>")
        node = doc.root

        node["xml:lang"] = "en-GB"

        assert_empty(node.namespace_definitions.map(&:prefix))

        child_node = Nokogiri::XML::Node.new("foo", doc)
        node << child_node

        assert_empty(node.namespace_definitions.map(&:prefix))
      end

      def test_append_child_element_with_prefixed_attributes
        doc = Nokogiri::XML("<root/>")
        node = doc.root

        assert_empty(node.namespace_definitions.map(&:prefix))

        child_node = Nokogiri::XML::Node.new("foo", doc)
        child_node["xml:lang"] = "en-GB"

        node << child_node

        assert_empty(child_node.namespace_definitions.map(&:prefix))
      end

      def test_namespace_key?
        doc = Nokogiri.XML(simple_xml_with_namespaces)
        node = doc.at_css("node")

        assert(node.namespaced_key?("foo", "http://tenderlovemaking.com/"))
        assert(node.namespaced_key?("foo", nil))
        refute(node.namespaced_key?("foo", "foo"))
      end

      def test_set_attribute_frees_nodes
        skip_unless_libxml2("JRuby doesn't do GC.")

        refute_valgrind_errors do
          document = Nokogiri::XML.parse("<foo></foo>")

          node = document.root
          node["visible"] = "foo"
          attribute = node.attribute("visible")
          text = Nokogiri::XML::Text.new("bar", document)
          attribute.add_child(text)

          stress_memory_while do
            node["visible"] = "attr"
          end
        end
      end
    end
  end
end
