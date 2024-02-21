# encoding: utf-8
# frozen_string_literal: true

require "helper"

if Nokogiri.uses_gumbo?
  class TestHtml5Serialize < Nokogiri::TestCase
    def test_nonstandard_elements_in_errors
      doc = Nokogiri::HTML5.fragment("<table><foo></foo></table>", max_errors: 100)
      assert_equal(2, doc.errors.length)
      assert_match(/Start tag 'foo'/, doc.errors.first.to_s.lines.first)
    end

    def test_nonstandard_elements_in_tag_stack
      doc = Nokogiri::HTML5.fragment("<foo><table><br></table></foo>", max_errors: 100)
      assert_equal(1, doc.errors.length)
      assert_match(/Currently open tags: html, foo, table/, doc.errors.first.to_s.lines.first)
    end
  end
end
