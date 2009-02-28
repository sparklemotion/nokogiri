require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

require 'nkf'

module Nokogiri
  module HTML
    class TestNode < Nokogiri::TestCase
      def test_before_will_prepend_text_nodes
        html = Nokogiri::HTML(<<-eohtml)
        <html>
          <head></head>
          <body>
            <div>first</div>
          </body>
        </html>
        eohtml

        assert node = html.at('//body').children.first
        node.before "some text"
        assert_equal 'some text', html.at('//body').children.first.content.strip
      end

      def test_after_will_append_text_nodes
        html = Nokogiri::HTML(<<-eohtml)
        <html>
          <head></head>
          <body>
            <div>first</div>
          </body>
        </html>
        eohtml

        assert node = html.at('//body/div')
        node.after "some text"
        assert_equal 'some text', node.next.text.strip
      end

      def test_replace
        doc = Nokogiri::HTML(<<-eohtml)
          <html>
            <head></head>
            <body>
              <center><img src='logo.gif' /></center>
            </body>
          </html>
        eohtml
        center = doc.at("//center")
        img = center.search("//img")
        assert_raises ArgumentError do
          center.replace img
        end
      end

      def test_to_html_does_not_contain_entities
        html = NKF.nkf("-e --msdos", <<-EOH)
        <html><body>
        <p> test paragraph
        foo bar </p>
        </body></html>
        EOH
        nokogiri = Nokogiri::HTML.parse(html)

        assert_equal "<p>testparagraph\r\nfoobar</p>",
          nokogiri.at("p").to_html.gsub(/ /, '')
      end
    end
  end
end
