require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module HTML
    class TestBuilder < Nokogiri::TestCase
      def test_hash_as_attributes
        builder = Nokogiri::HTML::Builder.new do
          div(:id => 'awesome') {
            h1 "america"
          }
        end
        assert_equal('<div id="awesome"><h1>america</h1></div>',
                     builder.doc.root.to_html.gsub(/\n/, '').gsub(/>\s*</, '><'))
      end

      def test_has_ampersand
        builder = Nokogiri::HTML::Builder.new do
          div.rad.thing! {
            text "<awe&some>"
            b "hello & world"
          }
        end
        assert_equal(
          '<div class="rad" id="thing">&lt;awe&amp;some&gt;<b>hello &amp; world</b></div>',
                     builder.doc.root.to_html.gsub(/\n/, ''))
      end

      def test_multi_tags
        builder = Nokogiri::HTML::Builder.new do
          div.rad.thing! {
            text "<awesome>"
            b "hello"
          }
        end
        assert_equal(
          '<div class="rad" id="thing">&lt;awesome&gt;<b>hello</b></div>',
                     builder.doc.root.to_html.gsub(/\n/, ''))
      end

      def test_attributes_plus_block
        builder = Nokogiri::HTML::Builder.new do
          div.rad.thing! {
            text "<awesome>"
          }
        end
        assert_equal('<div class="rad" id="thing">&lt;awesome&gt;</div>',
                     builder.doc.root.to_html.chomp)
      end

      def test_builder_adds_attributes
        builder = Nokogiri::HTML::Builder.new do
          div.rad.thing! "tender div"
        end
        assert_equal('<div class="rad" id="thing">tender div</div>',
                     builder.doc.root.to_html.chomp)
      end

      def test_bold_tag
        builder = Nokogiri::HTML::Builder.new do
          b "bold tag"
        end
        assert_equal('<b>bold tag</b>', builder.doc.root.to_html.chomp)
      end

      def test_html_then_body_tag
        builder = Nokogiri::HTML::Builder.new do
          html {
            body {
              b "bold tag"
            }
          }
        end
        assert_equal('<html><body><b>bold tag</b></body></html>',
                     builder.doc.root.to_html.chomp.gsub(/>\s*</, '><'))
      end
      
      def test_instance_eval_with_delegation_to_block_context
        class << self
          def foo
            "foo!"
          end
        end

        builder = Nokogiri::HTML::Builder.new { text foo }
        assert builder.to_html.include?("foo!")
      end
    end
  end
end
