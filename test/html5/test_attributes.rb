# frozen_string_literal: true

require "helper"

class TestHtml5Attributes < Nokogiri::TestCase
  def test_serialize_attribute
    html = <<~HTML
      <div id='foo' class="bar baz"></div>
    HTML
    div = Nokogiri::HTML5::DocumentFragment.parse(html).at_css("div")
    attrs = div.attribute_nodes
    id_attr = attrs.find { |a| a.name == "id" }
    class_attr = attrs.find { |a| a.name == "class" }

    assert_equal('id="foo"', id_attr.to_html)
    assert_equal('class="bar baz"', class_attr.to_html)
  end
end if Nokogiri.uses_gumbo?
