# frozen_string_literal: true

require "helper"

describe "compaction" do
  def skip_compaction_tests
    !GC.respond_to?(:verify_compaction_references)
  end

  describe Nokogiri::XML::Node do
    it "compacts safely" do # https://github.com/sparklemotion/nokogiri/pull/2579
      skip if skip_compaction_tests

      refute_valgrind_errors do
        big_doc = "<root>" + ("a".."zz").map { |x| "<#{x}>#{x}</#{x}>" }.join + "</root>"
        doc = Nokogiri.XML(big_doc)

        # ensure a bunch of node objects have been wrapped
        doc.root.children.each(&:inspect)

        # compact the heap and try to get the node wrappers to move
        gc_verify_compaction_references

        # access the node wrappers and make sure they didn't move
        doc.root.children.each(&:inspect)
      end
    end
  end

  describe Nokogiri::XML::Namespace do
    it "namespace_scopes" do
      skip if skip_compaction_tests

      doc = Nokogiri::XML(<<~EOF)
        <root xmlns="http://example.com/root" xmlns:bar="http://example.com/bar">
          <first/>
          <second xmlns="http://example.com/child"/>
          <third xmlns:foo="http://example.com/foo"/>
        </root>
      EOF

      refute_valgrind_errors do
        doc.at_xpath("//root:first", "root" => "http://example.com/root").namespace_scopes.inspect

        gc_verify_compaction_references

        doc.at_xpath("//root:first", "root" => "http://example.com/root").namespace_scopes.inspect
      end
    end

    it "remove_namespaces!" do
      skip if skip_compaction_tests

      doc = Nokogiri::XML(<<~XML)
        <root xmlns:a="http://a.flavorjon.es/" xmlns:b="http://b.flavorjon.es/">
          <a:foo>hello from a</a:foo>
          <b:foo>hello from b</b:foo>
          <container xmlns:c="http://c.flavorjon.es/">
            <c:foo c:attr='attr-value'>hello from c</c:foo>
          </container>
        </root>
      XML

      refute_valgrind_errors do
        namespaces = doc.root.namespaces
        namespaces.each(&:inspect)
        doc.remove_namespaces!

        gc_verify_compaction_references

        namespaces.each(&:inspect)
      end
    end
  end

  describe Nokogiri::XML::SAX::PushParser do
    it "keeps parsing after compaction" do
      skip("GC compaction is unavailable") if skip_compaction_tests

      # Keep the SAX parser off the machine stack so only PushParser's @sax_parser references it.
      parser = Nokogiri::XML::SAX::PushParser.new(Nokogiri::SAX::TestCase::Doc.new)

      gc_verify_compaction_references

      parser << "<root><alpha/></root>"
      parser.finish

      assert_equal([["root", []], ["alpha", []]], parser.document.start_elements)
    end
  end

  describe Nokogiri::HTML4::SAX::PushParser do
    it "keeps parsing after compaction" do
      skip("GC compaction is unavailable") if skip_compaction_tests

      parser = Nokogiri::HTML4::SAX::PushParser.new(Nokogiri::SAX::TestCase::Doc.new)

      gc_verify_compaction_references

      parser << "<html><body><p>hello</p></body></html>"
      parser.finish

      assert_equal(["html", "body", "p"], parser.document.start_elements.map(&:first))
    end
  end

  describe Nokogiri::XML::Reader do
    it "reads an IO after compaction" do
      skip("GC compaction is unavailable") if skip_compaction_tests

      # Construct the IO in a separate frame so a live stack reference cannot pin it.
      reader = -> { Nokogiri::XML::Reader.from_io(StringIO.new("<root>#{"<a/>" * 100}</root>")) }.call

      gc_verify_compaction_references

      names = []
      reader.each { |node| names << node.name if node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT }

      assert_equal(["root"] + (["a"] * 100), names)
    end

    it "reads a String after compaction" do
      skip("GC compaction is unavailable") if skip_compaction_tests

      # libxml2 < 2.11 reads this embedded string lazily, so its buffer must stay pinned.
      reader = -> { Nokogiri::XML::Reader.from_memory(+"<root><a>hello</a></root>") }.call

      gc_verify_compaction_references

      values = []
      reader.each { |node| values << node.value if node.value? }

      assert_equal(["hello"], values)
    end
  end

  describe Nokogiri::XSLT::Stylesheet do
    it "calls extension functions after compaction" do
      skip("GC compaction is unavailable") if skip_compaction_tests

      handler = Class.new do
        def reverse(nodes)
          nodes.first.content.reverse
        end
      end

      # Parse in a separate frame so a live stack reference cannot pin the stylesheet.
      stylesheet = lambda do
        Nokogiri::XSLT.parse(<<~XSL, "http://nokogiri.org/test/compaction" => handler)
          <xsl:stylesheet version="1.0"
            xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            xmlns:f="http://nokogiri.org/test/compaction"
            extension-element-prefixes="f">
            <xsl:template match="/">
              <reversed><xsl:value-of select="f:reverse(root)"/></reversed>
            </xsl:template>
          </xsl:stylesheet>
        XSL
      end.call

      gc_verify_compaction_references

      result = stylesheet.transform(Nokogiri::XML("<root>hello</root>"))

      assert_equal("olleh", result.root.content)
    end

    it "transforms with params when compaction runs while params are converted" do
      skip("GC compaction is unavailable") if skip_compaction_tests
      skip_unless_libxml2("JRuby does not convert params with #to_str")

      compact = method(:gc_verify_compaction_references)
      compacting_param = Object.new
      compacting_param.define_singleton_method(:to_str) do
        compact.call
        "'ok'"
      end

      stylesheet = Nokogiri::XSLT(<<~XSLT)
        <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
          <xsl:param name="title"/>
          <xsl:param name="trigger"/>
          <xsl:template match="/"><out><xsl:value-of select="$title"/></out></xsl:template>
        </xsl:stylesheet>
      XSLT

      # Short strings are embedded in their object slots, so compaction moves their bytes.
      params = ["title", "'Employee List'", "trigger", compacting_param]

      result = stylesheet.transform(Nokogiri::XML("<root/>"), params)

      assert_equal("Employee List", result.root.content)
    end

    it "calls extension functions when compaction runs during the transform" do
      skip("GC compaction is unavailable") if skip_compaction_tests

      compacting_handler = Class.new do
        def compact(_nodes)
          GC.verify_compaction_references(expand_heap: true, toward: :empty)
          "compacted"
        end
      end

      reversing_handler = Class.new do
        def reverse(nodes)
          nodes.first.content.reverse
        end
      end

      stylesheet = Nokogiri::XSLT.parse(
        <<~XSL,
          <xsl:stylesheet version="1.0"
            xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            xmlns:c="http://nokogiri.org/test/compaction/compact"
            xmlns:r="http://nokogiri.org/test/compaction/reverse"
            extension-element-prefixes="c r">
            <xsl:template match="/">
              <result><xsl:value-of select="c:compact(root)"/><xsl:value-of select="r:reverse(root)"/></result>
            </xsl:template>
          </xsl:stylesheet>
        XSL
        "http://nokogiri.org/test/compaction/compact" => compacting_handler,
        "http://nokogiri.org/test/compaction/reverse" => reversing_handler,
      )

      result = stylesheet.transform(Nokogiri::XML("<root>hello</root>"))

      assert_equal("compactedolleh", result.root.content)
    end
  end

  describe Nokogiri::XML::SAX::ParserContext do
    it "parses an IO after compaction" do
      skip("GC compaction is unavailable") if skip_compaction_tests

      context = -> { Nokogiri::XML::SAX::ParserContext.io(StringIO.new("<root><alpha/></root>")) }.call

      gc_verify_compaction_references

      handler = Nokogiri::SAX::TestCase::Doc.new
      context.parse_with(Nokogiri::XML::SAX::Parser.new(handler))

      assert_equal([["root", []], ["alpha", []]], handler.start_elements)
    end
  end

  describe Nokogiri::HTML4::SAX::ParserContext do
    it "parses an IO after compaction" do
      skip("GC compaction is unavailable") if skip_compaction_tests

      context = -> { Nokogiri::HTML4::SAX::ParserContext.io(StringIO.new("<html><body><p>hello</p></body></html>")) }.call

      gc_verify_compaction_references

      handler = Nokogiri::SAX::TestCase::Doc.new
      context.parse_with(Nokogiri::HTML4::SAX::Parser.new(handler))

      assert_equal(["html", "body", "p"], handler.start_elements.map(&:first))
    end
  end

  describe Nokogiri::XML::Document do
    let(:prefixes) { Array.new(10) { |i| "p#{i}" } }
    let(:doc) { Nokogiri::XML(%(<root #{prefixes.map { |p| %(xmlns:#{p}="urn:#{p}") }.join(" ")}><a/><b/></root>)) }
    let(:expected) { doc.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0, prefixes) }

    it "canonicalizes with inclusive namespaces when compaction runs while they are converted" do
      skip("GC compaction is unavailable") if skip_compaction_tests

      compact = method(:gc_verify_compaction_references)
      compacting_prefix = Object.new
      compacting_prefix.define_singleton_method(:to_str) do
        compact.call
        "p9"
      end

      # Short strings are embedded in their object slots, so compaction moves their bytes.
      inclusive_namespaces = prefixes[0..-2].map(&:dup) + [compacting_prefix]

      assert_equal(expected, doc.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0, inclusive_namespaces))
    end

    it "canonicalizes with inclusive namespaces when compaction runs in the block" do
      skip("GC compaction is unavailable") if skip_compaction_tests

      expected # canonicalize before compaction can run
      inclusive_namespaces = prefixes.map(&:dup)
      compacted = false

      actual = doc.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0, inclusive_namespaces) do
        gc_verify_compaction_references unless compacted
        compacted = true
      end

      assert_equal(expected, actual)
    end

    it "canonicalizes with inclusive namespaces when compaction runs while they are copied" do
      skip("GC compaction is unavailable") if skip_compaction_tests
      skip("GC.stress is too slow under a memory debugger") if Nokogiri::MemoryDebugger.active?

      to_str_class = Struct.new(:str) do
        def to_str = str.dup
      end
      inclusive_namespaces = prefixes.map { |p| to_str_class.new(p) }
      expected # canonicalize before compaction can run

      auto_compact = GC.auto_compact
      results = begin
        GC.auto_compact = true
        stress_memory_while do
          Array.new(20) { doc.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0, inclusive_namespaces) }
        end
      ensure
        GC.auto_compact = auto_compact
      end

      assert_equal([expected], results.uniq)
    end
  end
end
