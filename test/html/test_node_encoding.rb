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
        expected = encoded
        assert_equal expected, doc.fragment(hex).to_s
        assert_equal expected, doc.fragment(decimal).to_s
        assert_equal expected, doc.fragment(encoded).to_s

        doc.encoding = 'US-ASCII'
        expected = Nokogiri.jruby? ? hex : decimal
        assert_equal expected, doc.fragment(hex).to_s
        assert_equal expected, doc.fragment(decimal).to_s
        assert_equal expected, doc.fragment(encoded).to_s
      end
    end
  end
end
