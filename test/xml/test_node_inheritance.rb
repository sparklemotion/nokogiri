# frozen_string_literal: true

# issue#560

require "helper"

module Nokogiri
  module XML
    class TestNodeInheritance < Nokogiri::TestCase
      MyNode = Class.new(Nokogiri::XML::Node)
      def setup
        super
        @node = MyNode.new("foo", Nokogiri::XML::Document.new)
        @node["foo"] = "bar"
      end

      def test_node_name
        assert_equal("foo", @node.name)
      end

      def test_node_writing_an_attribute_accessing_via_attributes
        assert(@node.attributes["foo"])
      end

      def test_node_writing_an_attribute_accessing_via_key
        assert(@node.key?("foo"))
      end

      def test_node_writing_an_attribute_accessing_via_brackets
        assert_equal("bar", @node["foo"])
      end
    end
  end
end
