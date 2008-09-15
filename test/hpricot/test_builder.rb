#!/usr/bin/env ruby

require 'test/unit'
require "nokogiri/hpricot"

class TestBuilder < Test::Unit::TestCase
  include Nokogiri

  def test_escaping_text
    doc = Hpricot() { b "<a\"b>" }
    assert_equal "<b>&lt;a&quot;b&gt;</b>", doc.to_html
    assert_equal %{<a"b>}, doc.at("text()").to_s
  end

  def test_no_escaping_text
    doc = Hpricot() { div.test.me! { text "<a\"b>" } }
    assert_equal %{<div class="test" id="me"><a"b></div>}, doc.to_html
    assert_equal %{<a"b>}, doc.at("text()").to_s
  end

  def test_latin1_entities
    doc = Hpricot() { b "\200\225" }
    assert_equal "<b>&#8364;&#8226;</b>", doc.to_html
    assert_equal "\342\202\254\342\200\242", doc.at("text()").to_s
  end
end
