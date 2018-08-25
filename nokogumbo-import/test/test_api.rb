# encoding: utf-8
require 'nokogumbo'
require 'minitest/autorun'

class TestAPI < Minitest::Test
  def test_parse_convenience_methods
    html = '<!DOCTYPE html><p>hi'.freeze
    base = Nokogiri::HTML5::Document.parse(html)
    html5_parse = Nokogiri::HTML5.parse(html)
    html5 = Nokogiri::HTML5(html)
    str = base.to_html
    assert_equal str, html5_parse.to_html
    assert_equal str, html5.to_html
  end

  def test_fragment_convenience_methods
    frag = '<div><p>hi</div>'.freeze
    base = Nokogiri::HTML5::DocumentFragment.parse(frag)
    html5_fragment = Nokogiri::HTML5.fragment(frag)
    assert_equal base.to_html, html5_fragment.to_html
  end

  def test_url
    html = '<p>hi'
    url = 'http://example.com'
    doc = Nokogiri::HTML5::Document.parse(html, url, max_errors: 1)
    assert_equal url, doc.errors[0].file

    doc = Nokogiri::HTML5.parse(html, url, max_errors: 1)
    assert_equal url, doc.errors[0].file

    doc = Nokogiri::HTML5(html, url, max_errors: 1)
    assert_equal url, doc.errors[0].file
  end

  def test_parse_encoding
    utf8 = '<!DOCTYPE html><body><p>おはようございます'
    shift_jis = utf8.encode(Encoding::SHIFT_JIS)
    raw = shift_jis.dup
    raw.force_encoding(Encoding::ASCII_8BIT)

    assert_match(/おはようございます/, Nokogiri::HTML5(utf8).to_s)
    assert_match(/おはようございます/, Nokogiri::HTML5(shift_jis).to_s)
    refute_match(/おはようございます/, Nokogiri::HTML5(raw).to_s)

    assert_match(/おはようございます/, Nokogiri::HTML5(raw, nil, Encoding::SHIFT_JIS).to_s)
    assert_match(/おはようございます/, Nokogiri::HTML5.parse(raw, nil, Encoding::SHIFT_JIS).to_s)
    assert_match(/おはようございます/, Nokogiri::HTML5::Document.parse(raw, nil, Encoding::SHIFT_JIS).to_s)
  end

  def test_fragment_encoding
    utf8 = '<div><p>おはようございます</div>'
    shift_jis = utf8.encode(Encoding::SHIFT_JIS)
    raw = shift_jis.dup
    raw.force_encoding(Encoding::ASCII_8BIT)

    assert_match(/おはようございます/, Nokogiri::HTML5.fragment(utf8).to_s)
    assert_match(/おはようございます/, Nokogiri::HTML5.fragment(shift_jis).to_s)
    refute_match(/おはようございます/, Nokogiri::HTML5.fragment(raw).to_s)

    assert_match(/おはようございます/, Nokogiri::HTML5.fragment(raw, Encoding::SHIFT_JIS).to_s)
    assert_match(/おはようございます/, Nokogiri::HTML5::DocumentFragment.parse(raw, Encoding::SHIFT_JIS).to_s)
  end
end
