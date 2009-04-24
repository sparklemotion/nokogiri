require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestDocumentFragment < Nokogiri::TestCase
      def setup
        super
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
      end

      def test_new
        fragment = Nokogiri::XML::DocumentFragment.new(@xml)
      end

      def test_fragment_should_have_document
        fragment = Nokogiri::XML::DocumentFragment.new(@xml)
        assert_equal @xml, fragment.document
      end

      def test_name
        fragment = Nokogiri::XML::DocumentFragment.new(@xml)
        assert_equal '#document-fragment', fragment.name
      end

      def test_many_fragments
        100.times { Nokogiri::XML::DocumentFragment.new(@xml) }
      end
    end
  end
end
