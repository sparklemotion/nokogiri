require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestDocumentFragment < Nokogiri::TestCase
      def test_new
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        fragment = Nokogiri::XML::DocumentFragment.new(@xml)
      end
    end
  end
end
