require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module HTML
    class TestDocument < Nokogiri::TestCase
      def setup
        @html = Nokogiri::HTML.parse(File.read(HTML_FILE))
      end

      def test_html?
        assert !@html.xml?
        assert @html.html?
      end
    end
  end
end

