#!/usr/bin/env ruby

require 'test/unit'
require 'nokogiri'

class TestBuilder < Test::Unit::TestCase
  def test_escaping_text
    doc = Nokogiri() { b "<a\"b>" }
    assert_equal "<b>&lt;a&quot;b&gt;</b>", doc.to_html
    assert_equal %{<a"b>}, doc.at("text()").to_s
  end

  def test_no_escaping_text
    doc = Nokogiri() { div.test.me! { text "<a\"b>" } }
    assert_equal %{<div class="test" id="me"><a"b></div>}, doc.to_html
    assert_equal %{<a"b>}, doc.at("text()").to_s
  end

  def test_latin1_entities
    doc = Nokogiri() { b "\200\225" }
    assert_equal "<b>&#8364;&#8226;</b>", doc.to_html
    assert_equal "\342\202\254\342\200\242", doc.at("text()").to_s
  end
end
