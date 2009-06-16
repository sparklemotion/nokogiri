require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

require 'nkf'

module Nokogiri
  module HTML
    class TestNode < Nokogiri::TestCase
      def setup
        super
        @html = Nokogiri::HTML(<<-eohtml)
        <html>
          <head></head>
          <body>
            <div class='baz'><a href="foo" class="bar">first</a></div>
          </body>
        </html>
        eohtml
      end

      def test_description
        assert desc = @html.at('a.bar').description
        assert_equal 'a', desc.name
      end

      def test_add_next_sibling_with_empty_nodeset
        assert_raises(ArgumentError) {
          @html.at('a').add_next_sibling(@html.at('head').children)
        }
      end

      def test_add_next_sibling_with_non_empty_nodeset
        assert_raises(ArgumentError) {
          @html.at('head').add_next_sibling(@html.at('div').children)
        }
      end

      def test_ancestors_with_selector
        assert node = @html.at('a.bar').child
        assert list = node.ancestors('.baz')
        assert_equal 1, list.length
        assert_equal 'div', list.first.name
      end

      def test_css_matches?
        assert node = @html.at('a.bar')
        assert node.matches?('a.bar')
      end

      def test_xpath_matches?
        assert node = @html.at('//a')
        assert node.matches?('//a')
      end

      def test_swap
        @html.at('div').swap('<a href="foo">bar</a>')
        a_tag = @html.css('a').first
        assert_equal 'body', a_tag.parent.name
        assert_equal 0, @html.css('div').length
      end

      def test_swap_with_regex_characters
        @html.at('div').swap('<a href="foo">ba)r</a>')
        a_tag = @html.css('a').first
        assert_equal 'ba)r', a_tag.text
      end

      def test_attribute_decodes_entities
        node = @html.at('div')
        node['href'] = 'foo&bar'
        assert_equal 'foo&bar', node['href']
        node['href'] += '&baz'
        assert_equal 'foo&bar&baz', node['href']
      end


      def test_before_will_prepend_text_nodes
        assert node = @html.at('//body').children.first
        node.before "some text"
        assert_equal 'some text', @html.at('//body').children[0].content.strip
      end

      def test_fragment_handler_does_not_regurge_on_invalid_attributes
        iframe = %Q{<iframe style="width: 0%; height: 0px" src="http://someurl" allowtransparency></iframe>}
        assert_nothing_raised { @html.at('div').before(iframe) }
        assert_nothing_raised { @html.at('div').after(iframe) }
        assert_nothing_raised { @html.at('div').inner_html=(iframe) }
      end

      def test_inner_html=
        assert div = @html.at('//div')
        div.inner_html = '<span>testing</span>'
        assert_equal 'span', div.children.first.name

        div.inner_html = 'testing'
        assert_equal 'testing', div.content
      end

      def test_fragment
        fragment = @html.fragment(<<-eohtml)
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

      def test_fragment_serialization
        fragment = Nokogiri::HTML.fragment("<div>foo</div>")
        assert_equal "<div>foo</div>", fragment.serialize.chomp
        assert_equal "<div>foo</div>", fragment.to_xml.chomp
        assert_equal "<div>foo</div>", fragment.inner_html
        assert_equal "<div>foo</div>", fragment.to_html
        assert_equal "<div>foo</div>", fragment.to_s
      end

      def test_after_will_append_text_nodes
        assert node = @html.at('//body/div')
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

        if RUBY_PLATFORM =~ /java/
          # NKF linebreak modes are not supported as of jruby 1.2
          # see http://jira.codehaus.org/browse/JRUBY-3602 for status
          assert_equal "<p>testparagraph\nfoobar</p>",
            nokogiri.at("p").to_html.gsub(/ /, '')
        else
          assert_equal "<p>testparagraph\r\nfoobar</p>",
            nokogiri.at("p").to_html.gsub(/ /, '')
        end
      end
    end
  end
end
