# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    describe XPathContext do
      it "can register and deregister namespaces" do
        doc = Document.parse(<<~XML)
          <root xmlns="http://nokogiri.org/default" xmlns:ns1="http://nokogiri.org/ns1">
            <child>default</child>
            <ns1:child>ns1</ns1:child>
          </root>
        XML

        xc = XPathContext.new(doc)

        assert_raises(XPath::SyntaxError) do
          xc.evaluate("//foo:child")
        end

        xc.register_namespaces({ "foo" => "http://nokogiri.org/default" })
        assert_pattern do
          xc.evaluate("//foo:child") => [
            { name: "child", namespace: { href: "http://nokogiri.org/default" } }
          ]
        end

        xc.register_namespaces({ "foo" => nil })
        assert_raises(XPath::SyntaxError) do
          xc.evaluate("//foo:child")
        end
      end

      it "can register and deregister variables" do
        doc = Nokogiri::XML.parse(File.read(TestBase::XML_FILE), TestBase::XML_FILE)

        xc = XPathContext.new(doc)

        assert_raises(XPath::SyntaxError) do
          xc.evaluate("//address[@domestic=$value]")
        end

        xc.register_variables({ "value" => "Yes" })
        nodes = xc.evaluate("//address[@domestic=$value]")
        assert_equal(4, nodes.length)

        xc.register_variables({ "value" => "Qwerty" })
        nodes = xc.evaluate("//address[@domestic=$value]")
        assert_empty(nodes)

        xc.register_variables({ "value" => nil })
        assert_raises(XPath::SyntaxError) do
          xc.evaluate("//address[@domestic=$value]")
        end
      end

      it "#node=" do
        doc = Nokogiri::XML::Document.parse(<<~XML)
          <root>
            <child><foo>one</foo></child>
            <child><foo>two</foo></child>
            <child><foo>three</foo></child>
          </root>
        XML

        xc = XPathContext.new(doc)
        results = xc.evaluate(".//foo")
        assert_equal(3, results.length)

        xc.node = doc.root.elements[0]
        assert_pattern { xc.evaluate(".//foo") => [{ name: "foo", inner_html: "one" }] }

        xc.node = doc.root.elements[1]
        assert_pattern { xc.evaluate(".//foo") => [{ name: "foo", inner_html: "two" }] }
      end

      describe "argument that is not a Node" do
        let(:doc) { Nokogiri::XML::Document.parse("<root xmlns:ns='http://example.com/ns'/>") }
        let(:not_nodes) { [nil, "not a node", [], doc.root.namespace_definitions.first] }

        it ".new raises TypeError" do
          not_nodes.each do |not_node|
            assert_raises(TypeError) { XPathContext.new(not_node) }
          end
        end

        it "#node= raises TypeError" do
          xc = XPathContext.new(doc)
          not_nodes.each do |not_node|
            assert_raises(TypeError) { xc.node = not_node }
          end
        end
      end

      describe "when a custom function handler raises" do
        before { skip_unless_libxml2("the C extension's handling of a raise") }

        let(:raising_handler) do
          Class.new do
            def boom(_nodes = nil)
              raise "boom"
            end

            def invalid_return_type
              Object.new
            end

            def called_after_raise
              "called"
            end
          end.new
        end

        it "raises the handler's exception" do
          doc = Nokogiri::XML::Document.parse("<root/>")

          e = assert_raises(RuntimeError) { doc.xpath("nokogiri:boom()", raising_handler) }
          assert_equal("boom", e.message)
        end

        it "raises when the handler returns an unsupported type" do
          doc = Nokogiri::XML::Document.parse("<root/>")

          e = assert_raises(RuntimeError) { doc.xpath("nokogiri:invalid_return_type()", raising_handler) }
          assert_equal("Invalid return type", e.message)
        end

        it "does not leave the handler registered on the context" do
          xc = XPathContext.new(Nokogiri::XML::Document.parse("<root/>"))

          assert_raises(RuntimeError) { xc.evaluate("nokogiri:boom()", raising_handler) }

          assert_raises(XPath::SyntaxError) { xc.evaluate("nokogiri:called_after_raise()") }
        end

        it "does not leave the handler registered when the handler's respond_to? raises" do
          handler = Class.new do
            def respond_to_missing?(name, include_private = false)
              raise "respond_to? boom"
            end
          end.new
          xc = XPathContext.new(Nokogiri::XML::Document.parse("<root/>"))

          e = assert_raises(RuntimeError) { xc.evaluate("nokogiri:missing()", handler) }
          assert_equal("respond_to? boom", e.message)

          assert_raises(XPath::SyntaxError) { xc.evaluate("nokogiri:missing()") }
        end

        it "raises the handler's exception even if building an XPath error would rescue an exception" do
          XPath::SyntaxError.prepend(Module.new do
            def initialize(...)
              if Thread.current[:rescue_while_initializing_xpath_syntax_error]
                begin
                  raise "secondary"
                rescue RuntimeError
                  nil
                end
              end
              super
            end
          end)
          handler = Class.new do
            def respond_to_missing?(name, include_private = false)
              raise "respond_to? boom"
            end
          end.new
          xc = XPathContext.new(Nokogiri::XML::Document.parse("<root/>"))

          Thread.current[:rescue_while_initializing_xpath_syntax_error] = true
          e = assert_raises(RuntimeError) { xc.evaluate("nokogiri:missing()", handler) }
          assert_equal("respond_to? boom", e.message)
        ensure
          Thread.current[:rescue_while_initializing_xpath_syntax_error] = nil
        end

        it "does not leave libxml2's error handlers pointing at freed memory" do
          doc = Nokogiri::XML::Document.parse("<root/>")
          assert_raises(RuntimeError) { doc.xpath("nokogiri:boom()", raising_handler) }
          GC.start(full_mark: true, immediate_sweep: true)
          Array.new(10_000) { |i| "reuse the freed slot #{i}" }

          doc.root.write_to(StringIO.new, encoding: "unsupported-encoding")
        end
      end
    end
  end
end
