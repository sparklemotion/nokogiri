# encoding: utf-8
require 'nokogumbo'
require 'minitest/autorun'

class TestNokogumbo < Minitest::Test
  def test_to_xml
    xml = Nokogiri.HTML5('<!DOCTYPE html><source>').to_xml
    assert_match(/\A<\?xml version/, xml)
    assert_match(/<source\s*\/>/, xml)
  end

  def test_html4_fragment
    frag = Nokogiri::HTML.fragment('<span></span>')
    assert frag.is_a?(Nokogiri::HTML::DocumentFragment)
  end
end
