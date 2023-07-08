# frozen_string_literal: true

require "helper"

class TestMemoryLeak < Nokogiri::TestCase
  def setup
    super
    @str = <<~EOF
      <!DOCTYPE HTML>
      <html>
        <body>
          <br />
        </body>
      </html>
    EOF
  end

  #
  #  this suite is turned off unless the env var NOKOGIRI_GC is non-nil
  #
  #  to run any of these tests, do something like this on the commandline:
  #
  #    $ NOKOGIRI_GC=t ruby -Ilib:test \
  #          test/test_memory_leak.rb \
  #          -n /test_leaking_namespace_node_strings/
  #
  #  also see:
  #
  #    https://github.com/sparklemotion/nokogiri/issues/1603
  #
  #  which is an open issue to resurrect these tests and run them as
  #  part of the CI pipeline.
  #
  if ENV["NOKOGIRI_GC"] # turning these off by default for now
    def test_dont_hurt_em_why
      content = File.read("#{File.dirname(__FILE__)}/files/dont_hurt_em_why.xml")
      ndoc = Nokogiri::XML(content)
      2.times do
        ndoc.search("status text").first.inner_text
        ndoc.search("user name").first.inner_text
        GC.start
      end
    end

    class BadIO
      def read(*args)
        raise "hell"
      end

      def write(*args)
        raise "chickens"
      end
    end

    def test_for_mem_leak_on_io_callbacks
      io = File.open(SNUGGLES_FILE)
      Nokogiri::XML.parse(io)

      loop do
        Nokogiri::XML.parse(BadIO.new) rescue nil # rubocop:disable Style/RescueModifier
        doc.write(BadIO.new) rescue nil # rubocop:disable Style/RescueModifier
      end
    end

    def test_for_memory_leak
      #  we don't use Dike in any tests, but requiring it has side effects
      #  that can create memory leaks, and that's what we're testing for.
      require "rubygems"
      require "dike" # do not remove!

      count_start = count_object_space_documents
      xml_data = <<-EOS
        <test>
          <items>
            <item>abc</item>
            <item>1234</item>
            <item>Zzz</item>
          <items>
        </test>
      EOS
      20.times do
        doc = Nokogiri::XML(xml_data)
        doc.xpath("//item")
      end
      2.times { GC.start }
      count_end = count_object_space_documents
      assert((count_end - count_start) <= 2, "memory leak detected")
    rescue LoadError
      puts "\ndike is not installed, skipping memory leak test"
    end

    def test_leak_on_node_replace
      loop do
        doc = Nokogiri.XML("<root><foo /></root>")
        n = Nokogiri::XML::CDATA.new(doc, "bar")
        pivot = doc.root.children[0]
        pivot.replace(n)
      end
    end

    def test_sax_parser_context
      io = StringIO.new(@str)

      loop do
        Nokogiri::XML::SAX::ParserContext.new(@str)
        Nokogiri::XML::SAX::ParserContext.new(io)
        io.rewind

        Nokogiri::HTML4::SAX::ParserContext.new(@str)
        Nokogiri::HTML4::SAX::ParserContext.new(io)
        io.rewind
      end
    end

    class JumpingSaxHandler < Nokogiri::XML::SAX::Document
      def initialize(jumptag)
        @jumptag = jumptag
        super()
      end

      def start_element(name, attrs = [])
        throw(@jumptag)
      end
    end

    def test_jumping_sax_handler
      doc = JumpingSaxHandler.new(:foo)

      loop do
        catch(:foo) do
          Nokogiri::HTML4::SAX::Parser.new(doc).parse(@str)
        end
      end
    end

    def test_in_context_parser_leak
      loop do
        doc = Nokogiri::XML::Document.new
        fragment1 = Nokogiri::XML::DocumentFragment.new(doc, "<foo/>")
        node = fragment1.children[0]
        node.parse("<bar></bar>")
      end
    end

    def test_in_context_parser_leak_ii
      loop { Nokogiri::XML("<a/>").root.parse("<b/>") }
    end

    def test_leak_on_xpath_string_function
      doc = Nokogiri::XML(@str)
      loop do
        doc.xpath("name(//node())")
      end
    end

    def test_builder_namespace_node_strings_no_prefix
      # see https://github.com/sparklemotion/nokogiri/issues/1810 for memory leak report
      ns = { "xmlns" => "http://schemas.xmlsoap.org/soap/envelope/" }
      20.times do
        10_000.times do
          Nokogiri::XML::Builder.new do |xml|
            xml.send(:Envelope, ns) do
              xml.send(:Foobar, ns)
            end
          end
        end
        puts MemInfo.rss
      end
    end

    def test_builder_namespace_node_strings_with_prefix
      # see https://github.com/sparklemotion/nokogiri/issues/1810 for memory leak report
      ns = { "xmlns:foo" => "http://schemas.xmlsoap.org/soap/envelope/" }
      20.times do
        10_000.times do
          Nokogiri::XML::Builder.new do |xml|
            xml.send(:Envelope, ns) do
              xml.send(:Foobar, ns)
            end
          end
        end
        puts MemInfo.rss
      end
    end

    def test_document_remove_namespaces_with_ruby_objects
      xml = <<~XML
        <root xmlns:a="http://a.flavorjon.es/" xmlns:b="http://b.flavorjon.es/">
          <a:foo>hello from a</a:foo>
          <b:foo>hello from b</b:foo>
          <container xmlns:c="http://c.flavorjon.es/">
            <c:foo c:attr='attr-value'>hello from c</c:foo>
          </container>
        </root>
      XML

      20.times do
        10_000.times do
          doc = Nokogiri::XML::Document.parse(xml)
          doc.namespaces.each(&:inspect)
          doc.remove_namespaces!
        end
        puts MemInfo.rss
      end
    end

    def test_document_remove_namespaces_without_ruby_objects
      xml = <<~XML
        <root xmlns:a="http://a.flavorjon.es/" xmlns:b="http://b.flavorjon.es/">
          <a:foo>hello from a</a:foo>
          <b:foo>hello from b</b:foo>
          <container xmlns:c="http://c.flavorjon.es/">
            <c:foo c:attr='attr-value'>hello from c</c:foo>
          </container>
        </root>
      XML

      20.times do
        20_000.times do
          doc = Nokogiri::XML::Document.parse(xml)
          doc.remove_namespaces!
        end
        puts MemInfo.rss
      end
    end

    def test_xpath_namespaces
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

      20.times do
        10_000.times do
          ctx.evaluate("//namespace::*")
        end
        puts MemInfo.rss
      end
    end

    def test_leaking_dtd_nodes_after_internal_subset_removal
      # see https://github.com/sparklemotion/nokogiri/issues/1784
      100_000.times do |i|
        doc = Nokogiri::HTML4::Document.new
        doc.internal_subset.remove
        puts MemInfo.rss if i % 1000 == 0
      end
    end

    describe "#2114 RelaxNG schema parsing has a small memory leak" do
      it "no longer leaks" do
        prev_rss = MemInfo.rss
        100_001.times do |j|
          Nokogiri::XML::RelaxNG.from_document(Nokogiri::XML::Document.parse(File.read(ADDRESS_SCHEMA_FILE)))
          next unless j % 10_000 == 0

          curr_rss = MemInfo.rss
          diff_rss = curr_rss - prev_rss
          printf("\n(iter %d) %d", j, curr_rss)
          printf(" (%s%d)", diff_rss >= 0 ? "+" : "-", diff_rss) if j > 0
          prev_rss = curr_rss
        end
        puts
      end
    end
  end # if NOKOGIRI_GC

  def test_object_space_memsize_of
    require "objspace"
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
    assert(more_children_size > base_size, "adding children should increase memsize")

    attributes_size = ObjectSpace.memsize_of(Nokogiri::XML(<<~XML))
      <root>
        <child a="b" c="d">asdf</child>
      </root>
    XML
    assert(attributes_size > base_size, "adding attributes should increase memsize")

    string_size = ObjectSpace.memsize_of(Nokogiri::XML(<<~XML))
      <root>
        <child>asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf</child>
      </root>
    XML
    assert(string_size > base_size, "longer strings should increase memsize")

    bigger_name_size = ObjectSpace.memsize_of(Nokogiri::XML(<<~XML))
      <root>
        <superduperamazingchild>asdf</superduperamazingchild>
      </root>
    XML
    assert(bigger_name_size > base_size, "longer tags should increase memsize")
  end

  def test_object_space_memsize_with_dtd
    # https://github.com/sparklemotion/nokogiri/issues/2923
    require "objspace"
    skip("memsize_of not defined") unless ObjectSpace.respond_to?(:memsize_of)

    doc = Nokogiri::XML(<<~XML)
      <?xml version="1.0"?>
      <!DOCTYPE staff PUBLIC "staff.dtd" [
        <!ATTLIST payment type CDATA "check">
      ]>
      <staff></staff>
    XML
    ObjectSpace.memsize_of(doc) # assert_does_not_crash
  end

  module MemInfo
    # from https://stackoverflow.com/questions/7220896/get-current-ruby-process-memory-usage
    # this is only going to work on linux
    PAGE_SIZE = begin
      %x(getconf PAGESIZE).chomp.to_i
    rescue
      4096
    end
    STATM_PATH = "/proc/#{Process.pid}/statm"
    STATM_FOUND = File.exist?(STATM_PATH)

    def self.rss
      if STATM_FOUND
        return (File.read(STATM_PATH).split(" ")[1].to_i * PAGE_SIZE) / 1024
      end

      0
    end
  end

  private

  def count_object_space_documents
    count = 0
    ObjectSpace.each_object { |j| count += 1 if j.is_a?(Nokogiri::XML::Document) }
    count
  end
end
