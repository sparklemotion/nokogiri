# encoding: utf-8
# frozen_string_literal: true

require "helper"

class TestHtml5SerializationMonkeyPatch < Nokogiri::TestCase
  def test_to_xml
    xml = Nokogiri.HTML5("<!DOCTYPE html><source>").to_xml
    assert_match(/\A<\?xml version/, xml)
    assert_match(%r{<source\s*/>}, xml)
  end

  def test_html4_fragment
    frag = Nokogiri::HTML4.fragment("<span></span>")
    assert_kind_of(Nokogiri::HTML4::DocumentFragment, frag)
  end
end if Nokogiri.uses_gumbo?
