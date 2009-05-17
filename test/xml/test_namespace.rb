require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestNamespace < Nokogiri::TestCase
      def setup
        @xml = Nokogiri::XML <<-eoxml
          <root xmlns="http://tenderlovemaking.com/" xmlns:foo="bar">
            <awesome/>
          </root>
        eoxml
      end

      def test_namespace_node_prefix
        namespaces = @xml.root.namespace_definitions
        assert_equal [nil, 'foo'], namespaces.map { |x| x.prefix }
      end

      def test_namespace_node_href
        namespaces = @xml.root.namespace_definitions
        assert_equal [
          'http://tenderlovemaking.com/',
          'bar'
        ], namespaces.map { |x| x.href }
      end

      def test_equality
        namespaces = @xml.root.namespace_definitions
        assert_equal namespaces, @xml.root.namespace_definitions
      end
    end
  end
end
