# -*- coding: utf-8 -*-
require "helper"

module Nokogiri
  module HTML
    class TestNodeEncoding < Nokogiri::TestCase
      def test_inner_html
        doc = Nokogiri::HTML File.open(SHIFT_JIS_HTML, 'rb')

        hello = "こんにちは"

        contents = doc.at('h2').inner_html
        assert_equal doc.encoding, contents.encoding.name
        assert_match hello.encode('Shift_JIS'), contents

        contents = doc.at('h2').inner_html(:encoding => 'UTF-8')
        assert_match hello, contents

        doc.encoding = 'UTF-8'
        contents = doc.at('h2').inner_html
        assert_match hello, contents
      end

      def test_encoding_GH_1113
        doc = Nokogiri::HTML::Document.new
        hex = '<p>&#x1f340;</p>'
        decimal = '<p>&#127808;</p>'
        encoded = '<p>🍀</p>'

        doc.encoding = 'UTF-8'
        [hex, decimal, encoded].each do |document|
          assert_equal encoded, doc.fragment(document).to_s
        end

        doc.encoding = 'US-ASCII'
        expected = Nokogiri.jruby? ? hex : decimal
        [hex, decimal].each do |document|
          assert_equal expected, doc.fragment(document).to_s
        end
      end
    end
  end
end
