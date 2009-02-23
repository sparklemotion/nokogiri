require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

require 'nkf'

module Nokogiri
  module HTML
    class TestNode < Nokogiri::TestCase
      def test_to_html_does_not_contain_entities
        html = NKF.nkf("-e --msdos", <<-EOH)
        <html><body>
        <p> test paragraph
        foo bar </p>
        </body></html>
        EOH
        nokogiri = Nokogiri::HTML.parse(html)

        # Fuck.  libxml2 2.6.something breaks. ugh
        if Nokogiri::LIBXML_VERSION =~ /^2\.6\./
          assert_equal "<p>testparagraph\r\nfoobar</p>",
            nokogiri.at("p").dump_html.gsub(/ /, '')
        else
          assert_equal "<p>testparagraph\r\nfoobar</p>",
            nokogiri.at("p").to_html.gsub(/ /, '')
        end
      end
    end
  end
end
