# frozen_string_literal: true

require "helper"

describe "experimental pattern matching" do
  describe Nokogiri::XML::Namespace do
    describe "#deconstruct_keys" do
      let(:ns_default) { "http://nokogiri.org/ns/default" }
      let(:ns_noko) { "http://nokogiri.org/ns/noko" }
      let(:xmldoc) do
        Nokogiri::XML::Document.parse(<<~XML)
          <root xmlns="#{ns_default}" xmlns:noko="#{ns_noko}">
            <child1 foo="abc" noko:bar="def" />
            <noko:child2 foo="qwe" noko:bar="rty" />
          </root>
        XML
      end
      let(:child1) { xmldoc.at_xpath("//a:child1", { "a" => ns_default }) }
      let(:child2) { xmldoc.at_xpath("//b:child2", { "b" => ns_noko }) }

      it "supports :href" do
        href = child1.namespace.deconstruct_keys([:href])[:href]
        assert_instance_of(String, href)
        assert_equal(ns_default, href)

        href = child2.namespace.deconstruct_keys([:href])[:href]
        assert_instance_of(String, href)
        assert_equal(ns_noko, href)
      end

      it "supports :prefix" do
        prefix = child1.namespace.deconstruct_keys([:prefix])[:prefix]
        assert_nil(prefix)

        prefix = child2.namespace.deconstruct_keys([:prefix])[:prefix]
        assert_instance_of(String, prefix)
        assert_equal("noko", prefix)
      end
    end
  end

  describe Nokogiri::XML::Attr do
    describe "#deconstruct_keys" do
      let(:ns_default) { "http://nokogiri.org/ns/default" }
      let(:ns_noko) { "http://nokogiri.org/ns/noko" }
      let(:xmldoc) do
        Nokogiri::XML::Document.parse(<<~XML)
          <root xmlns="#{ns_default}" xmlns:noko="#{ns_noko}">
            <child1 foo="abc" noko:bar="def" />
          </root>
        XML
      end
      let(:child1) { xmldoc.at_xpath("//a:child1", { "a" => ns_default }) }
      let(:child1_attr_foo) { xmldoc.at_xpath("//a:child1/@foo", { "a" => ns_default }) }
      let(:child1_attr_bar) { xmldoc.at_xpath("//a:child1/@b:bar", { "a" => ns_default, "b" => ns_noko }) }

      it "supports :name" do
        name = child1_attr_foo.deconstruct_keys([:name])[:name]
        assert_instance_of(String, name)
        assert_equal("foo", name)

        name = child1_attr_bar.deconstruct_keys([:name])[:name]
        assert_instance_of(String, name)
        assert_equal("bar", name)
      end

      it "supports :value" do
        value = child1_attr_foo.deconstruct_keys([:value])[:value]
        assert_instance_of(String, value)
        assert_equal("abc", value)

        value = child1_attr_bar.deconstruct_keys([:value])[:value]
        assert_instance_of(String, value)
        assert_equal("def", value)
      end

      it "supports :namespace" do
        namespace = child1_attr_foo.deconstruct_keys([:namespace])[:namespace]
        assert_nil(namespace)

        namespace = child1_attr_bar.deconstruct_keys([:namespace])[:namespace]
        assert_instance_of(Nokogiri::XML::Namespace, namespace)
        assert_equal(child1_attr_bar.namespace, namespace)
      end
    end
  end

  describe Nokogiri::XML::NodeSet do
    describe "#deconstruct" do
      it "returns an array of the contained nodes" do
        doc = Nokogiri::XML::Document.parse(<<~XML)
          <root><child1/><child2/><child3/></root>
        XML

        actual = doc.root.children.deconstruct
        expected = doc.root.children.to_a

        assert_instance_of(Array, actual)
        assert_equal(3, actual.length)
        assert_equal(expected, actual)
      end
    end
  end

  describe Nokogiri::XML::Node do
    describe "#deconstruct_keys" do
      let(:ns_default) { "http://nokogiri.org/ns/default" }
      let(:ns_noko) { "http://nokogiri.org/ns/noko" }
      let(:xmldoc) do
        Nokogiri::XML::Document.parse(<<~XML)
          <root xmlns="#{ns_default}" xmlns:noko="#{ns_noko}">
            <child1 foo="abc" noko:bar="def" />
            <noko:child2 foo="qwe" noko:bar="rty" />
            <child3>
              <grandchild1 size="small">hello &amp; goodbye</grandchild1>
              <grandchild2 size="large"><!-- shhh --></grandchild2>
            </child3>
          </root>
        XML
      end
      let(:child1) { xmldoc.at_xpath("//a:child1", { "a" => ns_default }) }
      let(:child2) { xmldoc.at_xpath("//b:child2", { "b" => ns_noko }) }
      let(:child3) { xmldoc.at_xpath("//a:child3", { "a" => ns_default }) }
      let(:grandchild1) { xmldoc.at_xpath("//a:grandchild1", { "a" => ns_default }) }
      let(:grandchild2) { xmldoc.at_xpath("//a:grandchild2", { "a" => ns_default }) }

      it "supports :name" do
        name = child1.deconstruct_keys([:name])[:name]
        assert_instance_of(String, name)
        assert_equal("child1", name)

        name = child2.deconstruct_keys([:name])[:name]
        assert_instance_of(String, name)
        assert_equal("child2", name)
      end

      it "supports :attributes" do
        attributes = child1.deconstruct_keys([:attributes])[:attributes]
        assert_instance_of(Array, attributes)
        assert_equal(2, attributes.length)
        attributes.each { |attr| assert_instance_of(Nokogiri::XML::Attr, attr) }
        assert_equal(child1.attribute_nodes, attributes)
      end

      it "supports :namespace" do
        namespace = child1.deconstruct_keys([:namespace])[:namespace]
        assert_instance_of(Nokogiri::XML::Namespace, namespace)
        assert_equal(child1.namespace, namespace)

        namespace = child2.deconstruct_keys([:namespace])[:namespace]
        assert_instance_of(Nokogiri::XML::Namespace, namespace)
        assert_equal(child2.namespace, namespace)
      end

      it "supports :children" do
        children = child3.deconstruct_keys([:children])[:children]
        assert_instance_of(Nokogiri::XML::NodeSet, children)
        assert_equal(5, children.length) # includes whitespace text nodes!
        assert_equal(child3.children, children)
      end

      it "supports :elements" do
        elements = child3.deconstruct_keys([:elements])[:elements]
        assert_instance_of(Nokogiri::XML::NodeSet, elements)
        assert_equal(2, elements.length)
        assert_equal(["grandchild1", "grandchild2"], elements.map(&:name))
        assert_equal(child3.elements, elements)
      end

      it "supports :content" do
        content = grandchild1.deconstruct_keys([:content])[:content]
        assert_instance_of(String, content)
        assert_equal("hello & goodbye", content)

        content = grandchild2.deconstruct_keys([:content])[:content]
        assert_instance_of(String, content)
        assert_equal("", content)
      end

      it "supports :inner_html" do
        inner_html = grandchild1.deconstruct_keys([:inner_html])[:inner_html]
        assert_instance_of(String, inner_html)
        assert_equal("hello &amp; goodbye", inner_html)

        inner_html = grandchild2.deconstruct_keys([:inner_html])[:inner_html]
        assert_instance_of(String, inner_html)
        assert_equal("<!-- shhh -->", inner_html)
      end
    end
  end

  describe Nokogiri::XML::DocumentFragment do
    describe "#deconstruct" do
      it "returns an array of the contained nodes" do
        fragment = Nokogiri::XML::DocumentFragment.parse(<<~XML)
          <child1/><child2/><child3/>
        XML

        actual = fragment.deconstruct
        expected = fragment.children.to_a

        assert_instance_of(Array, actual)
        assert_equal(4, actual.length) # three elements and a whitespace text node
        assert_equal(expected, actual)
      end
    end
  end

  describe Nokogiri::XML::Document do
    describe "#deconstruct_keys" do
      it "supports :root" do
        doc = Nokogiri::XML::Document.parse(<<~XML)
          <root><child1/><child2/><child3/></root>
        XML

        root = doc.deconstruct_keys([:root])[:root]
        assert_instance_of(Nokogiri::XML::Element, root)
        assert_equal(doc.root, root)
      end
    end
  end

  unless RUBY_ENGINE == "truffleruby" # https://github.com/oracle/truffleruby/issues/3589
    describe "actual pattern matching" do
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
          assert_pattern do
            doc => { root: { children: [*, { name: "child3", children: grandchildren }, *] } }
            expected = doc.at_css("child3").children
            assert_equal(expected, grandchildren)
          end
        end

        it "finds nodes with namespaces" do
          ns = ns_default
          assert_pattern do
            doc => { root: { children: [*, { namespace: { href: ^ns }, name: "child3" }, *] } }
          end
        end

        it "finds node contents" do
          assert_pattern do
            doc => { root: { children: [*, { children: [*, {name: "grandchild1", content: }, *] }, *] } }
            assert_equal("hello & goodbye", content)
          end
        end

        it "finds node contents by attribute" do
          assert_pattern do
            doc => { root: { children: [*, { children: [*, {attributes: [*, {name: "size", value: "small"}, *], content: }, *] }, *] } }
            assert_equal("hello & goodbye", content)
          end
        end
      end

      describe "Fragment" do
        it "finds nodes" do
          assert_pattern do
            frag => [{name: "child1"}, {name: "child2"}, {name: "child3"}, {content: "\n"}]
          end
        end

        it "finds attributes" do
          assert_pattern do
            frag => [*, {name: "child2", attributes: }, *]
            assert_equal("foo", attributes.first.name)
          end
        end
      end

      describe "Node" do
        it "finds nodes" do
          assert_pattern do
            doc.root => { elements: [{name: "child1"}, {name: "child2"}, {name: "child3"}] }
          end
        end
      end
    end
  end
end
