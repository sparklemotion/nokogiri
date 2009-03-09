require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestDocumentFragment < Nokogiri::TestCase
      def test_new
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        fragment = Nokogiri::XML::DocumentFragment.new(@xml)
      end

      def test_fragment_should_have_document
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        fragment = Nokogiri::XML::DocumentFragment.new(@xml)
        assert_equal @xml, fragment.document
      end

      def test_name
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        fragment = Nokogiri::XML::DocumentFragment.new(@xml)
        assert_equal '#document-fragment', fragment.name
      end
    end
  end
end
