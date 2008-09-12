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

      def test_search
        assert @xml.search('//staff')
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
