require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module HTML
    class TestDocument < Nokogiri::TestCase
      def setup
        @html = Nokogiri::HTML.parse(File.read(HTML_FILE))
      end

      def test_HTML_function
        html = Nokogiri::HTML(File.read(HTML_FILE))
        assert html.html?
      end

      def test_find_classes
        doc = Nokogiri::HTML(<<-eohtml)
          <html>
            <body>
              <p class="red">RED</p>
              <p class="awesome red">RED</p>
              <p class="notred">GREEN</p>
              <p class="green notred">GREEN</p>
            </body>
          </html>
        eohtml
        list = doc.css('.red')
        assert_equal 2, list.length
        assert_equal %w{ RED RED }, list.map { |x| x.text }
      end

      def test_parse_can_take_io
        html = nil
        File.open(HTML_FILE, 'rb') { |f|
          html = Nokogiri::HTML(f)
        }
        assert html.html?
      end

      def test_html?
        assert !@html.xml?
        assert @html.html?
      end

      def test_serialize
        assert @html.serialize
        assert @html.to_html
      end
    end
  end
end

