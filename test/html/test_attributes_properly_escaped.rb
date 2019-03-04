require "helper"

module Nokogiri
  module HTML
    class TestAttributesProperlyEscaped < Nokogiri::TestCase
      unless Nokogiri::VersionInfo.instance.libxml2? && Nokogiri::VersionInfo.instance.libxml2_using_system?

        def test_attribute_macros_are_escaped
          html = "<p><i for=\"&{<test>}\"></i></p>"
          document = Nokogiri::HTML::Document.new
          nodes = document.parse(html)

          assert_equal("<p><i for=\"&amp;{&lt;test&gt;}\"></i></p>", nodes[0].to_s)
        end

        def test_libxml_escapes_server_side_includes
          original_html = %(<p><a href='<!--"><test>-->'></a></p>)
          document = Nokogiri::HTML::Document.new
          html = document.parse(original_html).to_s

          assert_match(/!--%22&gt;&lt;test&gt;/, html)
        end

        def test_libxml_escapes_server_side_includes_without_nested_quotes
          original_html = %(<p><i for="<!--<test>-->"></i></p>)
          document = Nokogiri::HTML::Document.new
          html = document.parse(original_html).to_s

          assert_match(/&lt;!--&lt;test&gt;/, html)
        end
      end
    end
  end
end
