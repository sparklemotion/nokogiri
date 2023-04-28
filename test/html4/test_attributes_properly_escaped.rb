# frozen_string_literal: true

require "helper"

module Nokogiri
  module HTML
    class TestAttributesProperlyEscaped < Nokogiri::TestCase
      def test_attribute_macros_are_escaped
        skip_unless_libxml2_patch("0001-Remove-script-macro-support.patch") if Nokogiri.uses_libxml?

        html = "<p><i for=\"&{<test>}\"></i></p>"
        document = Nokogiri::HTML4::Document.new
        nodes = document.parse(html)

        assert_equal("<p><i for=\"&amp;{&lt;test&gt;}\"></i></p>", nodes[0].to_s)
      end

      def test_libxml_escapes_server_side_includes
        skip_unless_libxml2_patch("0002-Update-entities-to-remove-handling-of-ssi.patch") if Nokogiri.uses_libxml?

        original_html = %(<p><a href='<!--"><test>-->'></a></p>)
        document = Nokogiri::HTML4::Document.new
        html = document.parse(original_html).to_s

        if Nokogiri.uses_libxml?(">= 2.11.0")
          assert_match(/!--"&gt;&lt;test&gt;/, html)
        else
          assert_match(/!--%22&gt;&lt;test&gt;/, html)
        end
      end

      def test_libxml_escapes_server_side_includes_without_nested_quotes
        skip_unless_libxml2_patch("0002-Update-entities-to-remove-handling-of-ssi.patch") if Nokogiri.uses_libxml?

        original_html = %(<p><i for="<!--<test>-->"></i></p>)
        document = Nokogiri::HTML4::Document.new
        html = document.parse(original_html).to_s

        assert_match(/&lt;!--&lt;test&gt;/, html)
      end
    end
  end
end
