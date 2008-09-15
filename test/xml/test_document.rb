require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestDocument < Nokogiri::TestCase
      def setup
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
      end

      def test_xml?
        assert @xml.xml?
      end

      def test_document
        assert @xml.document
      end

      def test_node_set_index
        assert node_set = @xml.search('//employee')

        assert_equal(5, node_set.length)
        assert node_set[4]
        assert_nil node_set[5]
      end

      def test_search
        assert node_set = @xml.search('//employee')

        assert_equal(5, node_set.length)

        node_set.each do |node|
          assert_equal('employee', node.name)
        end
      end

      def test_dump
        assert @xml.serialize
        assert @xml.to_xml
      end

      def test_new
        doc = nil
        assert_nothing_raised {
          doc = Nokogiri::XML::Document.new
        }
        assert doc
        assert doc.xml?
        assert_nil doc.root
      end

      def test_set_root
        doc = nil
        assert_nothing_raised {
          doc = Nokogiri::XML::Document.new
        }
        assert doc
        assert doc.xml?
        assert_nil doc.root
        node = Nokogiri::XML::Node.new("b") { |n|
          n.content = 'hello world'
        }
        assert_equal('hello world', node.content)
        doc.root = node
        assert_equal(node, doc.root)
      end
    end
  end
end
