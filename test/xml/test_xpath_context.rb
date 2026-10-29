# frozen_string_literal: true

require "helper"
require "open3"

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

      describe "Xalan DTM manager" do
        before { skip_unless_jruby }

        it "evaluates XPath and XSLT when Xalan is loaded by a parent of the JRuby class loader" do
          # https://github.com/sparklemotion/nokogiri/issues/3707
          xalan_jars = [org.apache.xpath.XPathContext, org.apache.xml.serializer.Serializer].map do |klass|
            klass.java_class.protection_domain.code_source.location.path
          end
          script = <<~RUBY
            require "nokogiri"
            java.lang.Thread.currentThread.setContextClassLoader(java.lang.ClassLoader.getSystemClassLoader)
            puts org.apache.xpath.XPathContext.java_class.class_loader == java.lang.ClassLoader.getSystemClassLoader
            puts Nokogiri::XML("<root/>").xpath("/root").length
            puts javax.xml.transform.TransformerFactory.newInstance.java_class.name
            stylesheet = Nokogiri::XSLT(%q(<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:template match="/"><out><xsl:value-of select="count(//p)"/></out></xsl:template></xsl:stylesheet>))
            puts stylesheet.transform(Nokogiri::XML("<r><p/><p/></r>")).root.text
          RUBY

          stdout, stderr, _status = Open3.capture3(
            { "CLASSPATH" => xalan_jars.join(File::PATH_SEPARATOR) },
            RbConfig.ruby,
            "-I", File.expand_path("../../lib", __dir__),
            "-I", File.expand_path("../../lib/nokogiri/jruby", __dir__),
            "-e", script
          )

          assert_equal(["true", "1", "org.apache.xalan.processor.TransformerFactoryImpl", "2"], stdout.lines(chomp: true), stderr)
        end

        it "does not set the JVM-wide system property" do
          Nokogiri::XML("<root/>").xpath("/root")

          assert_nil(java.lang.System.getProperty("org.apache.xml.dtm.DTMManager"))
        end

        it "uses XalanDTMManagerPatch" do
          doc = Nokogiri::XML("<root/>")
          doc.xpath("/root")

          xpath_context = doc.to_java.getUserData("CACHED_XPATH_CONTEXT")
          assert_equal("nokogiri.internals.XalanDTMManagerPatch", xpath_context.getDTMManager.java_class.name)
        end
      end
    end
  end
end
