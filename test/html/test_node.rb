require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

require 'nkf'

module Nokogiri
  module HTML
    class TestNode < Nokogiri::TestCase
      def test_attribute_decodes_entities
        html = Nokogiri::HTML(<<-eohtml)
        <html>
          <head></head>
          <body>
            <a>first</a>
          </body>
        </html>
        eohtml
        node = html.at('a')
        node['href'] = 'foo&bar'
        assert_equal 'foo&bar', node['href']
        node['href'] += '&baz'
        assert_equal 'foo&bar&baz', node['href']
      end


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

      def test_inner_html=
        html = Nokogiri::HTML(<<-eohtml)
        <html>
          <head></head>
          <body>
            <div>first</div>
          </body>
        </html>
        eohtml

        assert div = html.at('//div')
        div.inner_html = '<span>testing</span>'
        assert_equal 'span', div.children.first.name

        div.inner_html = 'testing'
        assert_equal 'testing', div.content
      end

      def test_fragment
        html = Nokogiri::HTML(<<-eohtml)
        <html>
          <head></head>
          <body>
            <div>first</div>
          </body>
        </html>
        eohtml
        fragment = html.fragment(<<-eohtml)
          hello
          <div class="foo">
            <p>bar</p>
          </div>
          world
        eohtml
        assert_match(/^hello/, fragment.inner_html.strip)
        assert_equal 3, fragment.children.length
        assert p_tag = fragment.css('p').first
        assert_equal 'div', p_tag.parent.name
        assert_equal 'foo', p_tag.parent['class']
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
