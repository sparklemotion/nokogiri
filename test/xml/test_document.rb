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
        assert path_ctx = @xml.search('//employee')
        assert path_ctx.node_set

        assert_equal(5, path_ctx.node_set.length)
        assert path_ctx.node_set[4]
        assert_nil path_ctx.node_set[5]
      end

      def test_search
        assert path_ctx = @xml.search('//employee')
        assert path_ctx.node_set

        assert_equal(5, path_ctx.node_set.length)

        path_ctx.node_set.each do |node|
          assert_equal('employee', node.name)
        end
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
    end
  end
end
