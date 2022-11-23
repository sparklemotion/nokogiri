# frozen_string_literal: true

# this file can't be parsed by versions of Ruby that don't support pattern matching. It's
# conditionally required by `test_pattern_matching.rb`

require "helper"

describe "experimental pattern matching" do
  let(:ns_default) { "http://nokogiri.org/ns/default" }
  let(:ns_noko) { "http://nokogiri.org/ns/noko" }
  let(:doc_xml) { <<~XML }
    <root xmlns="#{ns_default}" xmlns:noko="#{ns_noko}">
      <child1 foo="abc" noko:bar="def" />
      <noko:child2 foo="qwe" noko:bar="rty" />
      <child3>
        <grandchild1 size="small">hello &amp; goodbye</grandchild1>
        <grandchild2 size="large"><!-- shhh --></grandchild2>
      </child3>
    </root>
  XML
  let(:frag_xml) { <<~XML }
    <child1 /><child2 foo="bar" qwe="rty" /><child3 />
  XML
  let(:frag) { Nokogiri::XML::DocumentFragment.parse(frag_xml) }
  let(:doc) { Nokogiri::XML::Document.parse(doc_xml) }

  describe "Document" do
    it "finds nodes" do
      doc => { root: { children: [*, { name: "child3", children: grandchildren }, *] } }
      expected = doc.at_css("child3").children
      assert_equal(expected, grandchildren)
    end

    it "finds nodes with namespaces" do
      ns = ns_default
      # refute_raises
      doc => { root: { children: [*, { namespace: { href: ^ns }, name: "child3" }, *] } }
    end

    it "finds node contents" do
      doc => { root: { children: [*, { children: [*, {name: "grandchild1", content: }, *] }, *] } }
      assert_equal("hello & goodbye", content)
    end

    it "finds node contents by attribute" do
      doc => { root: { children: [*, { children: [*, {attributes: [*, {name: "size", value: "small"}, *], content: }, *] }, *] } }
      assert_equal("hello & goodbye", content)
    end
  end

  describe "Fragment" do
    it "finds nodes" do
      # refute_raises
      frag => [{name: "child1"}, {name: "child2"}, {name: "child3"}, {content: "\n"}]
    end

    it "finds attributes" do
      frag => [*, {name: "child2", attributes: }, *]
      assert_equal("foo", attributes.first.name)
    end
  end

  describe "Node" do
    it "finds nodes" do
      # refute_raises
      doc.root => { elements: [{name: "child1"}, {name: "child2"}, {name: "child3"}] }
    end
  end
end
