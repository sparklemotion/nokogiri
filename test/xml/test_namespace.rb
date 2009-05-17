require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestNamespace < Nokogiri::TestCase
      def test_namespace_node_prefix
        xml = Nokogiri::XML <<-eoxml
          <root xmlns="http://tenderlovemaking.com/" xmlns:foo="bar">
            <awesome/>
          </root>
        eoxml
        awesome = xml.root
        namespaces = awesome.namespace_definitions
        assert_equal [nil, 'foo'], namespaces.map { |x| x.prefix }
      end

      def test_namespace_node_href
        xml = Nokogiri::XML <<-eoxml
          <root xmlns="http://tenderlovemaking.com/" xmlns:foo="bar">
            <awesome/>
          </root>
        eoxml
        awesome = xml.root
        namespaces = awesome.namespace_definitions
        assert_equal [
          'http://tenderlovemaking.com/',
          'bar'
        ], namespaces.map { |x| x.href }
      end
    end
  end
end
