# frozen_string_literal: true

require "helper"
require "objspace"

class TestMemoryUsage < Nokogiri::TestCase
  describe "ObjectSpace.memsize_of" do
    it "includes children, attributes, strings, and tag names" do
      skip("memsize_of not defined") unless ObjectSpace.respond_to?(:memsize_of)

      base_size = ObjectSpace.memsize_of(Nokogiri::XML(<<~XML))
        <root>
          <child>asdf</child>
        </root>
      XML

      more_children_size = ObjectSpace.memsize_of(Nokogiri::XML(<<~XML))
        <root>
          <child>asdf</child>
          <child>asdf</child>
          <child>asdf</child>
        </root>
      XML
      assert_operator(more_children_size, :>, base_size, "adding children should increase memsize")

      attributes_size = ObjectSpace.memsize_of(Nokogiri::XML(<<~XML))
        <root>
          <child a="b" c="d">asdf</child>
        </root>
      XML
      assert_operator(attributes_size, :>, base_size, "adding attributes should increase memsize")

      string_size = ObjectSpace.memsize_of(Nokogiri::XML(<<~XML))
        <root>
          <child>asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf</child>
        </root>
      XML
      assert_operator(string_size, :>, base_size, "longer strings should increase memsize")

      bigger_name_size = ObjectSpace.memsize_of(Nokogiri::XML(<<~XML))
        <root>
          <superduperamazingchild>asdf</superduperamazingchild>
        </root>
      XML
      assert_operator(bigger_name_size, :>, base_size, "longer tags should increase memsize")
    end

    it "handles a DTD with attributes" do
      # https://github.com/sparklemotion/nokogiri/issues/2923
      skip("memsize_of not defined") unless ObjectSpace.respond_to?(:memsize_of)

      refute_valgrind_errors do
        doc = Nokogiri::XML(<<~XML)
          <?xml version="1.0"?>
          <!DOCTYPE staff PUBLIC "staff.dtd" [
            <!ATTLIST payment type CDATA "check">
          ]>
          <staff></staff>
        XML
        ObjectSpace.memsize_of(doc)
      end
    end
  end

  #
  #  This memory test suite will only work on Linux, and is off by default.
  #
  #  To run it along with the rest of the test suite with ruby_memcheck:
  #
  #    bundle exec rake test:memcheck
  #
  #  To run it in isolation with ruby_memcheck:
  #
  #    bundle exec rake test:memcheck TESTOPTS="-n/MEMORY_SUITE/"
  #    bundle exec rake test:memcheck TESTOPTS="-n/MEMORY_SUITE.*io_callbacks/" # run only one test
  #
  #  or to run it in isolation with an analysis of vmsize:
  #
  #    bundle exec rake test:memory_suite
  #
  describe "MEMORY_SUITE" do
    let(:basic_html) { <<~HTML }
      <!DOCTYPE HTML>
      <html>
        <body>
          <br />
        </body>
      </html>
    HTML

    describe "io callbacks" do
      class BadIO
        def read(*args)
          raise "hell"
        end

        def write(*args)
          raise "chickens"
        end
      end

      it "test_for_mem_leak_on_io_callbacks" do
        io = File.open(SNUGGLES_FILE)
        Nokogiri::XML.parse(io)

        memwatch(__method__) do
          Nokogiri::XML.parse(BadIO.new) rescue nil # rubocop:disable Style/RescueModifier
          doc.write(BadIO.new) rescue nil # rubocop:disable Style/RescueModifier
        end
      end
    end

    it "test_leak_on_node_replace" do
      memwatch(__method__) do
        doc = Nokogiri.XML("<root><foo /></root>")
        n = Nokogiri::XML::CDATA.new(doc, "bar")
        pivot = doc.root.children[0]
        pivot.replace(n)
      end
    end

    it "test_sax_parser_context" do
      io = StringIO.new(basic_html)

      memwatch(__method__) do
        Nokogiri::XML::SAX::ParserContext.new(basic_html)
        Nokogiri::XML::SAX::ParserContext.new(io)
        io.rewind

        Nokogiri::HTML4::SAX::ParserContext.new(basic_html)
        Nokogiri::HTML4::SAX::ParserContext.new(io)
        io.rewind
      end
    end

    describe "sax parser longjmp" do
      class JumpingSaxHandler < Nokogiri::XML::SAX::Document
        def initialize(jumptag)
          @jumptag = jumptag
          super()
        end

        def start_element(name, attrs = [])
          throw(@jumptag)
        end
      end

      it "test_jumping_sax_handler" do
        doc = JumpingSaxHandler.new(:foo)

        memwatch(__method__) do
          catch(:foo) do
            Nokogiri::HTML4::SAX::Parser.new(doc).parse(basic_html)
          end
        end
      end
    end

    it "test_in_context_parser_leak" do
      memwatch(__method__) do
        doc = Nokogiri::XML::Document.new
        fragment1 = Nokogiri::XML::DocumentFragment.new(doc, "<foo/>")
        node = fragment1.children[0]
        node.parse("<bar></bar>")
      end
    end

    it "test_in_context_parser_leak_ii" do
      memwatch(__method__) do
        Nokogiri::XML("<a/>").root.parse("<b/>")
      end
    end

    it "test_leak_on_xpath_string_function" do
      doc = Nokogiri::XML(basic_html)
      memwatch(__method__) do
        doc.xpath("name(//node())")
      end
    end

    it "test_builder_namespace_node_strings_no_prefix" do
      # see https://github.com/sparklemotion/nokogiri/issues/1810 for memory leak report
      ns = { "xmlns" => "http://schemas.xmlsoap.org/soap/envelope/" }
      memwatch(__method__) do
        Nokogiri::XML::Builder.new do |xml|
          xml.send(:Envelope, ns) do
            xml.send(:Foobar, ns)
          end
        end
      end
    end

    it "test_builder_namespace_node_strings_with_prefix" do
      # see https://github.com/sparklemotion/nokogiri/issues/1810 for memory leak report
      ns = { "xmlns:foo" => "http://schemas.xmlsoap.org/soap/envelope/" }
      memwatch(__method__) do
        Nokogiri::XML::Builder.new do |xml|
          xml.send(:Envelope, ns) do
            xml.send(:Foobar, ns)
          end
        end
      end
    end

    it "test_document_remove_namespaces_with_ruby_objects" do
      xml = <<~XML
        <root xmlns:a="http://a.flavorjon.es/" xmlns:b="http://b.flavorjon.es/">
          <a:foo>hello from a</a:foo>
          <b:foo>hello from b</b:foo>
          <container xmlns:c="http://c.flavorjon.es/">
            <c:foo c:attr='attr-value'>hello from c</c:foo>
          </container>
        </root>
      XML

      memwatch(__method__) do
        doc = Nokogiri::XML::Document.parse(xml)
        doc.namespaces.each(&:inspect)
        doc.remove_namespaces!
      end
    end

    it "test_document_remove_namespaces_without_ruby_objects" do
      xml = <<~XML
        <root xmlns:a="http://a.flavorjon.es/" xmlns:b="http://b.flavorjon.es/">
          <a:foo>hello from a</a:foo>
          <b:foo>hello from b</b:foo>
          <container xmlns:c="http://c.flavorjon.es/">
            <c:foo c:attr='attr-value'>hello from c</c:foo>
          </container>
        </root>
      XML

      memwatch(__method__) do
        doc = Nokogiri::XML::Document.parse(xml)
        doc.remove_namespaces!
      end
    end

    it "test_xpath_namespaces" do
      xml = <<~XML
        <root xmlns:a="http://a.flavorjon.es/" xmlns:b="http://b.flavorjon.es/">
          <a:foo>hello from a</a:foo>
          <b:foo>hello from b</b:foo>
          <container xmlns:c="http://c.flavorjon.es/">
            <c:foo c:attr='attr-value'>hello from c</c:foo>
          </container>
        </root>
      XML
      doc = Nokogiri::XML::Document.parse(xml)
      ctx = Nokogiri::XML::XPathContext.new(doc)

      memwatch(__method__) do
        ctx.evaluate("//namespace::*")
      end
    end

    it "test_leaking_dtd_nodes_after_internal_subset_removal" do
      # see https://github.com/sparklemotion/nokogiri/issues/1784
      memwatch(__method__) do
        doc = Nokogiri::HTML4::Document.new
        doc.internal_subset.remove
      end
    end

    it "#2114 RelaxNG schema parsing" do
      schema = File.read(ADDRESS_SCHEMA_FILE)
      memwatch(__method__) do
        Nokogiri::XML::RelaxNG.from_document(Nokogiri::XML::Document.parse(schema))
      end
    end

    it "Document doesn't leak a replaced node" do
      html1 = "<root>test</root>"
      html2 = "<root>#{"x" * 5000}</root>"
      memwatch(__method__) do
        doc = Nokogiri::XML(html1)
        doc2 = Nokogiri::XML(html2)
        doc2.root = doc.root
      end
    end

    it "test_text_node_robustness_gh1426" do
      # notably, the original bug report was about libxml-ruby interactions
      # this test should blow up under valgrind if we regress on libxml-ruby workarounds
      # side note: this was fixed in libxml-ruby 2.9.0 by https://github.com/xml4r/libxml-ruby/pull/119
      message = "<section><h2>BOOM!</h2></section>"
      memwatch(__method__) do
        node = Nokogiri::HTML4::DocumentFragment.parse(message).at_css("h2")
        node.add_previous_sibling(Nokogiri::XML::Text.new("before", node.document))
        node.add_next_sibling(Nokogiri::XML::Text.new("after", node.document))
      end
    end

    it "libgumbo abandoned tag name" do
      html = <<~HTML
        <asdfasdfasdfasdfasdfasdfasdfasdfasdfasdf foo="bar
      HTML

      # should increase over the first 200_000 iterations (general parsing overhead),
      # but then flatten out. on my machine at about 169k
      memwatch(__method__) do
        Nokogiri::HTML5::Document.parse(html)
      end
    end

    it "libgumbo max depth exceeded" do
      html = "<html><body>"

      memwatch(__method__) do
        Nokogiri::HTML5.parse(html, max_tree_depth: 1)
      rescue ArgumentError
        # Expected error. This comment makes rubocop happy.
      end
    end

    it "XML::SAX::ParserContext.io holds a reference to IO input" do
      content = File.read(XML_ATOM_FILE)

      memwatch(__method__) do
        pc = Nokogiri::XML::SAX::ParserContext.io(StringIO.new(content), "ISO-8859-1")
        parser = Nokogiri::XML::SAX::Parser.new(Nokogiri::SAX::TestCase::Doc.new)
        GC.stress
        pc.parse_with(parser)

        assert_equal(472, parser.document.data.length)
      end
    end

    it "XML::SAX::ParserContext.memory holds a reference to string input" do
      memwatch(__method__) do
        pc = Nokogiri::XML::SAX::ParserContext.memory(File.read(XML_ATOM_FILE), "ISO-8859-1")
        parser = Nokogiri::XML::SAX::Parser.new(Nokogiri::SAX::TestCase::Doc.new)
        GC.stress
        pc.parse_with(parser)

        assert_equal(472, parser.document.data.length)
      end
    end
  end if ENV["NOKOGIRI_MEMORY_SUITE"] && Nokogiri.uses_libxml?
end
