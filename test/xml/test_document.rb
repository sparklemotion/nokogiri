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

      def test_subset_is_decorated
        x = Module.new do
          def awesome!
          end
        end
        util_decorate(@xml, x)

        assert @xml.respond_to?(:awesome!)
        assert node_set = @xml.search('//staff')
        assert node_set.respond_to?(:awesome!)
        assert subset = node_set.search('.//employee')
        assert subset.respond_to?(:awesome!)
        assert sub_subset = node_set.search('.//name')
        assert sub_subset.respond_to?(:awesome!)
      end

      def test_decorator_is_applied
        x = Module.new do
          def awesome!
          end
        end
        util_decorate(@xml, x)

        assert @xml.respond_to?(:awesome!)
        assert node_set = @xml.search('//employee')
        assert node_set.respond_to?(:awesome!)
        node_set.each do |node|
          assert node.respond_to?(:awesome!)
        end
        assert @xml.root.respond_to?(:awesome!)
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

      def util_decorate(document, x)
        document.decorators['document'] << x
        document.decorators['node'] << x
        document.decorators['nodeset'] << x
        document.decorate!
      end
    end
  end
end
