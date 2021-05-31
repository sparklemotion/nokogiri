require "helper"

module Nokogiri
  module HTML
    class TestAttributesProperlyEscaped < Nokogiri::TestCase

      def test_attribute_macros_are_escaped
        if Nokogiri.uses_libxml? && !Nokogiri::VERSION_INFO["libxml"]["patches"]&.include?("0001-Remove-script-macro-support.patch")
          skip("libxml2 has not been patched to be safe against attribute macros")
        end

        html = "<p><i for=\"&{<test>}\"></i></p>"
        document = Nokogiri::HTML::Document.new
        nodes = document.parse(html)

        assert_equal("<p><i for=\"&amp;{&lt;test&gt;}\"></i></p>", nodes[0].to_s)
      end

      def test_libxml_escapes_server_side_includes
        if Nokogiri.uses_libxml? && !Nokogiri::VERSION_INFO["libxml"]["patches"]&.include?("0002-Update-entities-to-remove-handling-of-ssi.patch")
          skip("libxml2 has not been patched to be safe against SSI")
        end

        original_html = %(<p><a href='<!--"><test>-->'></a></p>)
        document = Nokogiri::HTML::Document.new
        html = document.parse(original_html).to_s

        assert_match(/!--%22&gt;&lt;test&gt;/, html)
      end

      def test_libxml_escapes_server_side_includes_without_nested_quotes
        if Nokogiri.uses_libxml? && !Nokogiri::VERSION_INFO["libxml"]["patches"]&.include?("0002-Update-entities-to-remove-handling-of-ssi.patch")
          skip("libxml2 has not been patched to be safe against SSI")
        end

        original_html = %(<p><i for="<!--<test>-->"></i></p>)
        document = Nokogiri::HTML::Document.new
        html = document.parse(original_html).to_s

        assert_match(/&lt;!--&lt;test&gt;/, html)
      end
    end
  end
end
