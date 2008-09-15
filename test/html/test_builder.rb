require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module HTML
    class TestBuilder < Nokogiri::TestCase
      def test_bold_tag
        builder = Nokogiri::HTML::Builder.new do
          b "bold tag"
        end
        assert_equal('<b>bold tag</b>', builder.doc.to_html.chomp)
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
                     builder.doc.to_html.chomp)
      end
    end
  end
end
