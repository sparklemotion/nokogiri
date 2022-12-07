# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestReader < Nokogiri::TestCase
      class NonStringIO
        def read(size)
          :invalid_object
        end
      end

      def test_io_non_string
        io = NonStringIO.new
        reader = Nokogiri::XML::Reader(io)
        assert_equal(io, reader.source)
      end

      def test_from_io_sets_io_as_source
        io = File.open(SNUGGLES_FILE)
        reader = Nokogiri::XML::Reader.from_io(io)
        assert_equal(io, reader.source)
      end

      def test_empty_element?
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
          <xml><city>Paris</city><state/></xml>
        eoxml

        results = reader.map do |node|
          if node.node_type == Nokogiri::XML::Node::ELEMENT_NODE
            node.empty_element?
          end
        end
        assert_equal([false, false, nil, nil, true, nil], results)
      end

      def test_self_closing?
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
          <xml><city>Paris</city><state/></xml>
        eoxml

        results = reader.map do |node|
          if node.node_type == Nokogiri::XML::Node::ELEMENT_NODE
            node.self_closing?
          end
        end
        assert_equal([false, false, nil, nil, true, nil], results)
      end

      # Issue #831
      # Make sure that the reader doesn't block reading the entire input
      def test_reader_blocking
        rd, wr = IO.pipe
        node_out = nil
        t = Thread.start do
          reader = Nokogiri::XML::Reader(rd, "UTF-8")
          reader.each do |node|
            node_out = node
            break
          end
          rd.close
        end
        sleep(0.1) # sleep to make sure the reader will actually block for input
        begin
          wr.puts "<foo>"
          wr.puts "<bar/>" * 10000
          wr.flush
        rescue Errno::EPIPE # rubocop:disable Lint/SuppressedException
        end
        res = t.join(1) # give the thread a moment to finish
        wr.close
        refute_nil(node_out, "Didn't read any nodes, exclude the trivial case")
        refute_nil(res, "Reader blocks trying to read the entire stream")
      end

      def test_reader_takes_block
        options = nil
        Nokogiri::XML::Reader(File.read(XML_FILE), XML_FILE) do |cfg|
          options = cfg
          options.nonet.nowarning.dtdattr
        end
        assert_predicate(options, :nonet?)
        assert_predicate(options, :nowarning?)
        assert_predicate(options, :dtdattr?)
      end

      def test_nil_raises
        assert_raises(ArgumentError) do
          Nokogiri::XML::Reader.from_memory(nil)
        end
        assert_raises(ArgumentError) do
          Nokogiri::XML::Reader.from_io(nil)
        end
      end

      def test_from_io
        io = File.open(SNUGGLES_FILE)
        reader = Nokogiri::XML::Reader.from_io(io)
        refute_predicate(reader, :default?)
        assert_equal([false, false, false, false, false, false, false],
          reader.map(&:default?))
      end

      def test_io
        io = File.open(SNUGGLES_FILE)
        reader = Nokogiri::XML::Reader(io)
        refute_predicate(reader, :default?)
        assert_equal([false, false, false, false, false, false, false],
          reader.map(&:default?))
      end

      def test_string_io
        io = StringIO.new(<<-eoxml)
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
        </x>
        eoxml
        reader = Nokogiri::XML::Reader(io)
        refute_predicate(reader, :default?)
        assert_equal([false, false, false, false, false, false, false],
          reader.map(&:default?))
      end

      class ReallyBadIO
        def read(size)
          "a" * size**10
        end
      end

      class ReallyBadIO4Java
        def read(size = 1)
          "a" * size**10
        end
      end

      def test_io_that_reads_too_much
        io = if Nokogiri.jruby?
          ReallyBadIO4Java.new
        else
          ReallyBadIO.new
        end
        Nokogiri::XML::Reader(io)
      end

      def test_in_memory
        assert(Nokogiri::XML::Reader(<<-eoxml))
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
        </x>
        eoxml
      end

      def test_reader_holds_on_to_string
        xml = <<-eoxml
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
        </x>
        eoxml
        reader = Nokogiri::XML::Reader(xml)
        assert_equal(xml, reader.source)
      end

      def test_default?
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
        </x>
        eoxml
        refute_predicate(reader, :default?)
        assert_equal([false, false, false, false, false, false, false],
          reader.map(&:default?))
      end

      def test_value?
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
        </x>
        eoxml
        refute_predicate(reader, :value?)
        assert_equal([false, true, false, true, false, true, false],
          reader.map(&:value?))
      end

      def test_read_error_document
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
          <foo>
        </x>
        eoxml
        assert_raises(Nokogiri::XML::SyntaxError) do
          reader.each { |node| }
        end
        assert_equal(1, reader.errors.length)
      end

      def test_errors_is_an_array
        reader = Nokogiri::XML::Reader(StringIO.new("&bogus;"))
        assert_raises(SyntaxError) do
          reader.read
        end
        assert_equal([SyntaxError], reader.errors.map(&:class))
      end

      def test_pushing_to_non_array_raises_TypeError
        skip_unless_libxml2("TODO: JRuby ext does not internally call `errors`")
        reader = Nokogiri::XML::Reader(StringIO.new("&bogus;"))
        def reader.errors
          1
        end
        assert_raises(TypeError) do
          reader.read
        end
      end

      def test_attributes?
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
        </x>
        eoxml
        refute_predicate(reader, :attributes?)
        assert_equal([true, false, true, false, true, false, true],
          reader.map(&:attributes?))
      end

      def test_reader_attributes
        reader = Nokogiri::XML::Reader.from_memory(<<~XML)
          <x xmlns:tenderlove='http://tenderlovemaking.com/' xmlns='http://mothership.connection.com/'>
            <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
          </x>
        XML
        assert_empty(reader.attributes)
        assert_equal([{ "xmlns:tenderlove" => "http://tenderlovemaking.com/",
                        "xmlns" => "http://mothership.connection.com/", },
                      {},
                      { "awesome" => "true" },
                      {},
                      { "awesome" => "true" },
                      {},
                      { "xmlns:tenderlove" => "http://tenderlovemaking.com/",
                        "xmlns" => "http://mothership.connection.com/", },],
          reader.map(&:attributes))
      end

      def test_reader_attributes_hash
        reader = Nokogiri::XML::Reader.from_memory(<<~XML)
          <x xmlns:tenderlove='http://tenderlovemaking.com/' xmlns='http://mothership.connection.com/'>
            <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
          </x>
        XML
        assert_empty(reader.attribute_hash)
        assert_equal([{},
                      {},
                      { "awesome" => "true" },
                      {},
                      { "awesome" => "true" },
                      {},
                      {},],
          reader.map(&:attribute_hash))
      end

      def test_reader_namespaces
        reader = Nokogiri::XML::Reader.from_memory(<<~XML)
          <x xmlns:tenderlove='http://tenderlovemaking.com/' xmlns='http://mothership.connection.com/'>
            <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
          </x>
        XML
        assert_empty(reader.namespaces)
        assert_equal([{ "xmlns:tenderlove" => "http://tenderlovemaking.com/",
                        "xmlns" => "http://mothership.connection.com/", },
                      {},
                      {},
                      {},
                      {},
                      {},
                      { "xmlns:tenderlove" => "http://tenderlovemaking.com/",
                        "xmlns" => "http://mothership.connection.com/", },],
          reader.map(&:namespaces))
      end

      def test_attribute_roundtrip
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:tenderlove='http://tenderlovemaking.com/'
           xmlns='http://mothership.connection.com/'
           >
          <tenderlove:foo awesome='true' size='giant'>snuggles!</tenderlove:foo>
        </x>
        eoxml
        reader.each do |node|
          node.attributes.each do |key, value|
            assert_equal(value, node.attribute(key))
          end
        end
      end

      def test_attribute_at
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
        </x>
        eoxml
        assert_nil(reader.attribute_at(nil))
        assert_nil(reader.attribute_at(0))
        assert_equal(["http://tenderlovemaking.com/", nil, "true", nil, "true", nil, "http://tenderlovemaking.com/"],
          reader.map { |x| x.attribute_at(0) })
      end

      def test_attribute
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
        </x>
        eoxml
        assert_nil(reader.attribute(nil))
        assert_nil(reader.attribute("awesome"))
        assert_equal([nil, nil, "true", nil, "true", nil, nil],
          reader.map { |x| x.attribute("awesome") })
      end

      def test_attribute_length
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
        </x>
        eoxml
        assert_equal(0, reader.attribute_count)
        assert_equal([1, 0, 1, 0, 0, 0, 0], reader.map(&:attribute_count))
      end

      def test_depth
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo>snuggles!</tenderlove:foo>
        </x>
        eoxml
        assert_equal(0, reader.depth)
        assert_equal([0, 1, 1, 2, 1, 1, 0], reader.map(&:depth))
      end

      def test_encoding
        string = <<-eoxml
        <awesome>
          <p xml:lang="en">The quick brown fox jumps over the lazy dog.</p>
          <p xml:lang="ja">日本語が上手です</p>
        </awesome>
        eoxml
        reader = Nokogiri::XML::Reader.from_memory(string, nil, "UTF-8")
        assert_equal(["UTF-8"], reader.map(&:encoding).uniq)
      end

      def test_xml_version
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo>snuggles!</tenderlove:foo>
        </x>
        eoxml
        assert_nil(reader.xml_version)
        assert_equal(["1.0"], reader.map(&:xml_version).uniq)
      end

      def test_lang
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <awesome>
          <p xml:lang="en">The quick brown fox jumps over the lazy dog.</p>
          <p xml:lang="ja">日本語が上手です</p>
        </awesome>
        eoxml
        assert_nil(reader.lang)
        assert_equal([nil, nil, "en", "en", "en", nil, "ja", "ja", "ja", nil, nil],
          reader.map(&:lang))
      end

      def test_value
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo>snuggles!</tenderlove:foo>
        </x>
        eoxml
        assert_nil(reader.value)
        assert_equal([nil, "\n          ", nil, "snuggles!", nil, "\n        ", nil],
          reader.map(&:value))
      end

      def test_prefix
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:edi='http://ecommerce.example.org/schema'>
          <edi:foo>hello</edi:foo>
        </x>
        eoxml
        assert_nil(reader.prefix)
        assert_equal([nil, nil, "edi", nil, "edi", nil, nil],
          reader.map(&:prefix))
      end

      def test_node_type
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x>
          <y>hello</y>
        </x>
        eoxml
        assert_equal(0, reader.node_type)
        assert_equal([1, 14, 1, 3, 15, 14, 15], reader.map(&:node_type))
      end

      def test_inner_xml
        str = "<x><y>hello</y></x>"
        reader = Nokogiri::XML::Reader.from_memory(str)

        reader.read

        assert_equal("<y>hello</y>", reader.inner_xml)
      end

      def test_outer_xml
        str = ["<x><y>hello</y></x>", "<y>hello</y>", "hello", "<y/>", "<x/>"]
        reader = Nokogiri::XML::Reader.from_memory(str.first)

        xml = []
        reader.map { |node| xml << node.outer_xml }

        assert_equal(str, xml)
      end

      def test_outer_xml_with_empty_nodes
        str = ["<x><y/></x>", "<y/>", "<x/>"]
        reader = Nokogiri::XML::Reader.from_memory(str.first)

        xml = []
        reader.map { |node| xml << node.outer_xml }

        assert_equal(str, xml)
      end

      def test_state
        reader = Nokogiri::XML::Reader.from_memory("<foo>bar</bar>")
        assert(reader.state)
      end

      def test_ns_uri
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:edi='http://ecommerce.example.org/schema'>
          <edi:foo>hello</edi:foo>
        </x>
        eoxml
        assert_nil(reader.namespace_uri)
        assert_equal([nil,
                      nil,
                      "http://ecommerce.example.org/schema",
                      nil,
                      "http://ecommerce.example.org/schema",
                      nil,
                      nil,],
          reader.map(&:namespace_uri))
      end

      def test_reader_node_attributes_keep_a_reference_to_the_reader
        skip_unless_libxml2("valgrind tests should only run with libxml2")

        attribute_nodes = []

        refute_valgrind_errors do
          xml = <<~EOF
            <root>
              <content first_name="bob" last_name="loblaw"/>
            </root>
          EOF

          reader = Nokogiri::XML::Reader.from_memory(xml)
          reader.each do |element|
            assert_output(nil, /Reader#attribute_nodes is deprecated/) do
              attribute_nodes += element.attribute_nodes
            end
          end
        end

        assert_operator(attribute_nodes.length, :>, 0)
        attribute_nodes.inspect
      end

      def test_namespaced_attributes
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:edi='http://ecommerce.example.org/schema' xmlns:commons="http://rets.org/xsd/RETSCommons">
          <edi:foo commons:street-number="43">hello</edi:foo>
          <y edi:name="francis" bacon="87"/>
        </x>
        eoxml
        attr_ns = []
        while reader.read
          next unless reader.node_type == Nokogiri::XML::Node::ELEMENT_NODE

          assert_output(nil, /Reader#attribute_nodes is deprecated/) do
            reader.attribute_nodes.each { |attr| attr_ns << (attr.namespace.nil? ? nil : attr.namespace.prefix) }
          end
        end
        assert_equal(["commons",
                      "edi",
                      nil,],
          attr_ns)
      end

      def test_local_name
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:edi='http://ecommerce.example.org/schema'>
          <edi:foo>hello</edi:foo>
        </x>
        eoxml
        assert_nil(reader.local_name)
        assert_equal(["x", "#text", "foo", "#text", "foo", "#text", "x"],
          reader.map(&:local_name))
      end

      def test_name
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
        <x xmlns:edi='http://ecommerce.example.org/schema'>
          <edi:foo>hello</edi:foo>
        </x>
        eoxml
        assert_nil(reader.name)
        assert_equal(["x", "#text", "edi:foo", "#text", "edi:foo", "#text", "x"],
          reader.map(&:name))
      end

      def test_base_uri
        reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
          <x xml:base="http://base.example.org/base/">
            <link href="link"/>
            <other xml:base="http://other.example.org/"/>
            <relative xml:base="relative">
              <link href="stuff" />
            </relative>
          </x>
        eoxml

        assert_nil(reader.base_uri)
        assert_equal(["http://base.example.org/base/",
                      "http://base.example.org/base/",
                      "http://base.example.org/base/",
                      "http://base.example.org/base/",
                      "http://other.example.org/",
                      "http://base.example.org/base/",
                      "http://base.example.org/base/relative",
                      "http://base.example.org/base/relative",
                      "http://base.example.org/base/relative",
                      "http://base.example.org/base/relative",
                      "http://base.example.org/base/relative",
                      "http://base.example.org/base/",
                      "http://base.example.org/base/",],
          reader.map(&:base_uri))
      end

      def test_xlink_href_without_base_uri
        reader = Nokogiri::XML::Reader(<<-eoxml)
          <x xmlns:xlink="http://www.w3.org/1999/xlink">
            <link xlink:href="#other">Link</link>
            <other id="other">Linked Element</other>
          </x>
        eoxml

        reader.each do |node|
          next unless node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT

          if node.name == "link"
            assert_nil(node.base_uri)
          end
        end
      end

      def test_xlink_href_with_base_uri
        reader = Nokogiri::XML::Reader(<<-eoxml)
          <x xml:base="http://base.example.org/base/"
             xmlns:xlink="http://www.w3.org/1999/xlink">
            <link xlink:href="#other">Link</link>
            <other id="other">Linked Element</other>
          </x>
        eoxml

        reader.each do |node|
          if node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
            assert_equal("http://base.example.org/base/", node.base_uri)
          end
        end
      end

      def test_read_from_memory
        called = false
        reader = Nokogiri::XML::Reader.from_memory("<foo>bar</foo>")
        reader.each do |node|
          called = true
          assert(node)
        end
        assert(called)
      end

      def test_large_document_smoke_test
        skip_unless_libxml2("valgrind tests should only run with libxml2")

        refute_valgrind_errors do
          xml = []
          xml << "<elements>"
          10000.times { |j| xml << "<element id=\"#{j}\"/>" }
          xml << "</elements>"
          xml = xml.join("\n")

          Nokogiri::XML::Reader.from_memory(xml).each(&:attributes)
        end
      end

      def test_correct_outer_xml_inclusion
        xml = Nokogiri::XML::Reader.from_io(StringIO.new(<<-eoxml))
          <root-element>
            <children>
              <child n="1">
                <field>child-1</field>
              </child>
              <child n="2">
                <field>child-2</field>
              </child>
              <child n="3">
                <field>child-3</field>
              </child>
            </children>
          </root-element>
        eoxml

        nodelengths = []
        has_child2 = []

        xml.each do |node|
          if (node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT) && (node.name == "child")
            nodelengths << node.outer_xml.length
            has_child2 << !!node.outer_xml.include?("child-2")
          end
        end

        assert_equal(nodelengths[0], nodelengths[1])
        assert(has_child2[1])
        refute(has_child2[0])
      end

      def test_correct_inner_xml_inclusion
        xml = Nokogiri::XML::Reader.from_io(StringIO.new(<<-eoxml))
          <root-element>
            <children>
              <child n="1">
                <field>child-1</field>
              </child>
              <child n="2">
                <field>child-2</field>
              </child>
              <child n="3">
                <field>child-3</field>
              </child>
            </children>
          </root-element>
        eoxml

        nodelengths = []
        has_child2 = []

        xml.each do |node|
          if (node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT) && (node.name == "child")
            nodelengths << node.inner_xml.length
            has_child2 << !!node.inner_xml.include?("child-2")
          end
        end

        assert_equal(nodelengths[0], nodelengths[1])
        assert(has_child2[1])
        refute(has_child2[0])
      end

      def test_nonexistent_attribute
        require "nokogiri"
        reader = Nokogiri::XML::Reader("<root xmlns='bob'><el attr='fred' /></root>")
        reader.read # root
        reader.read # el
        assert_nil(reader.attribute("other"))
      end

      def test_broken_markup_attribute_hash
        xml = <<~XML
          <root><foo bar="asdf" xmlns:quux="qwer">
        XML
        reader = Nokogiri::XML::Reader(xml)
        reader.read # root
        reader.read # foo

        assert_equal("foo", reader.name)
        if Nokogiri.jruby?
          assert_equal({ "bar" => "asdf" }, reader.attribute_hash)
        else
          assert_nil(reader.attribute_hash)
        end
      end

      def test_broken_markup_namespaces
        xml = <<~XML
          <root><foo bar="asdf" xmlns:quux="qwer">
        XML
        reader = Nokogiri::XML::Reader(xml)
        reader.read # root
        reader.read # foo

        assert_equal("foo", reader.name)
        if Nokogiri.jruby?
          assert_equal({ "xmlns:quux" => "qwer" }, reader.namespaces)
        else
          assert_nil(reader.namespaces)
        end
      end
    end
  end
end
