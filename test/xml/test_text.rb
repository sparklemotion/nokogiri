# frozen_string_literal: true

require "helper"

describe Nokogiri::XML::Text do
  describe ".new" do
    it "does constructor things" do
      doc = Nokogiri::XML::Document.new
      node = Nokogiri::XML::Text.new("hello world", doc)

      assert(node)
      assert_instance_of(Nokogiri::XML::Text, node)
      assert_equal("hello world", node.content)
      assert_same(doc, node.document)
    end

    it "accepts a node but warns about it" do
      doc = Nokogiri::XML::Document.new
      related_node = Nokogiri::XML::Element.new("foo", doc)
      node = nil

      assert_output(nil, /Passing a Node as the second parameter to Text.new is deprecated/) do
        node = Nokogiri::XML::Text.new("hello world", related_node)
      end
      assert(node)
      assert_instance_of(Nokogiri::XML::Text, node)
      assert_equal("hello world", node.content)
      assert_same(doc, node.document)
    end

    it "does not accept anything other than Node or Document" do
      assert_raises(TypeError) { Nokogiri::XML::Text.new("hello world", 1234) }
      assert_raises(TypeError) { Nokogiri::XML::Text.new("hello world", "asdf") }
      assert_raises(TypeError) { Nokogiri::XML::Text.new("hello world", {}) }
      assert_raises(TypeError) { Nokogiri::XML::Text.new("hello world", nil) }
    end
  end

  it "has a valid css path" do
    doc  = Nokogiri.XML("<root> foo <a>something</a> bar bazz </root>")
    node = doc.root.children[2]

    assert_instance_of(Nokogiri::XML::Text, node)
    assert_equal(node, doc.at_css(node.css_path))
  end

  it "supports #inspect" do
    node = Nokogiri::XML::Text.new("hello world", Nokogiri::XML::Document.new)
    assert_equal("#<#{node.class.name}:#{format("0x%x", node.object_id)} #{node.text.inspect}>", node.inspect)
  end

  it "supports #content and #content=" do
    node = Nokogiri::XML::Text.new("foo", Nokogiri::XML::Document.new)

    assert_equal("foo", node.content)

    node.content = "& <foo> &amp;"

    assert_equal("& <foo> &amp;", node.content)
    assert_equal("&amp; &lt;foo&gt; &amp;amp;", node.to_xml)
  end

  it "raises when adding a child" do
    doc = Nokogiri::XML::Document.new
    node = Nokogiri::XML::Text.new("foo", doc)
    exception_type = Nokogiri.jruby? ? RuntimeError : ArgumentError # TODO: make this consistent

    assert_raises(exception_type) { node.add_child(Nokogiri::XML::Text.new("bar", doc)) }
    assert_raises(exception_type) { node.add_child(Nokogiri::XML::Element.new("div", doc)) }
    assert_raises(exception_type) { node << Nokogiri::XML::Text.new("bar", doc) }
    assert_raises(exception_type) { node << Nokogiri::XML::Element.new("div", doc) }
  end

  it "supports #wrap" do
    xml = "<root><thing><div>important thing</div></thing></root>"
    doc = Nokogiri::XML(xml)
    text = doc.at_css("div").children.first
    text.wrap("<wrapper/>")

    assert_equal("wrapper", text.parent.name)
    assert_equal("wrapper", doc.at_css("div").children.first.name)
  end
end
