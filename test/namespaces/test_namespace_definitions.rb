# frozen_string_literal: true

require "helper"

describe "namespace definitions" do
  it "handles duplicate namespace definitions" do
    # https://github.com/sparklemotion/nokogiri/issues/1247
    doc = Nokogiri::XML::Document.parse("<root>")
    child1 = doc.create_element("a", "xmlns:foo" => "fooey")
    child2 = doc.create_element("b", "xmlns:foo" => "fooey")
    doc.root.add_child(child1)
    doc.root.add_child(child2)
    assert_equal("<a xmlns:foo=\"fooey\"/>", child1.to_xml)
    assert_equal("<b xmlns:foo=\"fooey\"/>", child2.to_xml)
  end
end
