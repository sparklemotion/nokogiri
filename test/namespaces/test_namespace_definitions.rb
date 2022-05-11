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

  it "handles multiple instances of a namespace definition" do
    # this describes behavior that is broken in JRuby related to the namespace cache and should be fixed
    # see https://github.com/sparklemotion/nokogiri/issues/2543
    doc = Nokogiri::XML::Document.parse("<root>")
    child1 = doc.create_element("a", "xmlns:foo" => "http://nokogiri.org/ns/foo")
    assert_equal(1, child1.namespace_definitions.length)
    child1.namespace_definitions.first.tap do |ns|
      assert_equal("foo", ns.prefix)
      assert_equal("http://nokogiri.org/ns/foo", ns.href)
    end

    child2 = doc.create_element("b", "xmlns:foo" => "http://nokogiri.org/ns/foo")
    pending_if("https://github.com/sparklemotion/nokogiri/issues/2543", Nokogiri.jruby?) do
      assert_equal(1, child2.namespace_definitions.length)
      child2.namespace_definitions.first.tap do |ns|
        assert_equal("foo", ns.prefix)
        assert_equal("http://nokogiri.org/ns/foo", ns.href)
      end
    end
  end
end
