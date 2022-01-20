# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestC14N < Nokogiri::TestCase
      # http://www.w3.org/TR/xml-c14n#Example-OutsideDoc
      def test_3_1
        doc = Nokogiri.XML(<<~eoxml)
          <?xml version="1.0"?>

          <?xml-stylesheet   href="doc.xsl"
             type="text/xsl"   ?>

          <!DOCTYPE doc SYSTEM "doc.dtd">

          <doc>Hello, world!<!-- Comment 1 --></doc>

          <?pi-without-data     ?>

          <!-- Comment 2 -->

          <!-- Comment 3 -->
        eoxml

        expected = <<~EOF.strip
          <?xml-stylesheet href="doc.xsl"
             type="text/xsl"   ?>
          <doc>Hello, world!</doc>
          <?pi-without-data?>
        EOF
        c14n = doc.canonicalize
        assert_equal(expected, c14n)
        c14n = doc.canonicalize(nil, nil, false)
        assert_equal(expected, c14n)

        expected = <<~EOF.strip
          <?xml-stylesheet href="doc.xsl"
             type="text/xsl"   ?>
          <doc>Hello, world!<!-- Comment 1 --></doc>
          <?pi-without-data?>
          <!-- Comment 2 -->
          <!-- Comment 3 -->
        EOF
        c14n = doc.canonicalize(nil, nil, true)
        assert_equal(expected, c14n)
      end

      def test_exclude_block_params
        xml = "<a><b></b></a>"
        doc = Nokogiri.XML(xml)

        list = []
        doc.canonicalize do |node, parent|
          list << [node, parent]
          true
        end
        if Nokogiri.jruby?
          assert_equal(
            ["a", "document", "document", nil, "b", "a"],
            list.flatten.map { |x| x ? x.name : x }
          )
        else
          assert_equal(
            ["a", "document", "document", nil, "b", "a", "a", "document"],
            list.flatten.map { |x| x ? x.name : x }
          )
        end
      end

      def test_exclude_block_true
        xml = "<a><b></b></a>"
        doc = Nokogiri.XML(xml)

        c14n = doc.canonicalize do |_node, _parent|
          true
        end
        assert_equal(xml, c14n)
      end

      def test_exclude_block_false
        xml = "<a><b></b></a>"
        doc = Nokogiri.XML(xml)

        c14n = doc.canonicalize do |_node, _parent|
          false
        end
        assert_equal("", c14n)
      end

      def test_exclude_block_conditional
        xml = "<root><a></a><b></b><c></c><d></d></root>"
        doc = Nokogiri.XML(xml)

        c14n = doc.canonicalize do |node, _parent|
          node.name == "root" || node.name == "a" || node.name == "c"
        end
        assert_equal("<root><a></a><c></c></root>", c14n)

        c14n = doc.canonicalize do |node, _parent|
          node.name == "a" || node.name == "c"
        end
        pending_if("java c14n is not completely compatible with libxml2 c14n", Nokogiri.jruby?) do
          assert_equal("<a></a><c></c>", c14n)
        end
      end

      def test_exclude_block_nil
        xml = "<a><b></b></a>"
        doc = Nokogiri.XML(xml)

        c14n = doc.canonicalize do |_node, _parent|
          nil
        end
        assert_equal("", c14n)
      end

      def test_exclude_block_object
        xml = "<a><b></b></a>"
        doc = Nokogiri.XML(xml)

        c14n = doc.canonicalize do |_node, _parent|
          Object.new
        end
        assert_equal(xml, c14n)
      end

      def test_c14n_node
        xml = "<a><b><c></c></b></a>"
        doc = Nokogiri.XML(xml)
        c14n = doc.at_xpath("//b").canonicalize
        assert_equal("<b><c></c></b>", c14n)
      end

      def test_c14n_modes
        # http://www.w3.org/TR/xml-exc-c14n/#sec-Enveloping

        doc1 = Nokogiri.XML(<<~EOXML)
          <n0:local xmlns:n0="http://foobar.org" xmlns:n3="ftp://example.org">
            <n1:elem2 xmlns:n1="http://example.net" xml:lang="en">
              <n3:stuff xmlns:n3="ftp://example.org"/>
            </n1:elem2>
          </n0:local>
        EOXML
        node1 = doc1.at_xpath("//n1:elem2", { "n1" => "http://example.net" })

        doc2 = Nokogiri.XML(<<~EOXML)
          <n2:pdu xmlns:n1="http://example.com"
                     xmlns:n2="http://foo.example"
                     xmlns:n4="http://foo.example"
                     xml:lang="fr"
                     xml:space="retain">
            <n1:elem2 xmlns:n1="http://example.net" xml:lang="en">
              <n3:stuff xmlns:n3="ftp://example.org"/>
              <n4:stuff />
            </n1:elem2>
          </n2:pdu>
        EOXML
        node2 = doc2.at_xpath("//n1:elem2", { "n1" => "http://example.net" })

        expected = <<~EOF.strip
          <n1:elem2 xmlns:n0="http://foobar.org" xmlns:n1="http://example.net" xmlns:n3="ftp://example.org" xml:lang="en">
              <n3:stuff></n3:stuff>
            </n1:elem2>
        EOF
        c14n = node1.canonicalize
        assert_equal(expected, c14n)

        expected = <<~EOF.strip
          <n1:elem2 xmlns:n1="http://example.net" xmlns:n2="http://foo.example" xmlns:n4="http://foo.example" xml:lang="en" xml:space="retain">
              <n3:stuff xmlns:n3="ftp://example.org"></n3:stuff>
              <n4:stuff></n4:stuff>
            </n1:elem2>
        EOF
        c14n = node2.canonicalize
        assert_equal(expected, c14n)
        c14n = node2.canonicalize(XML::XML_C14N_1_0)
        assert_equal(expected, c14n)
        assert_raises(RuntimeError) do
          node2.canonicalize(XML::XML_C14N_1_0, ["n2"])
        end

        expected = <<~EOF.strip
          <n1:elem2 xmlns:n1="http://example.net" xml:lang="en">
              <n3:stuff xmlns:n3="ftp://example.org"></n3:stuff>
            </n1:elem2>
        EOF
        c14n = node1.canonicalize(XML::XML_C14N_EXCLUSIVE_1_0)
        assert_equal(expected, c14n)

        expected = <<~EOF.strip
          <n1:elem2 xmlns:n1="http://example.net" xml:lang="en">
              <n3:stuff xmlns:n3="ftp://example.org"></n3:stuff>
              <n4:stuff xmlns:n4="http://foo.example"></n4:stuff>
            </n1:elem2>
        EOF
        c14n = node2.canonicalize(XML::XML_C14N_EXCLUSIVE_1_0)
        assert_equal(expected, c14n)

        expected = <<~EOF.strip
          <n1:elem2 xmlns:n1="http://example.net" xmlns:n2="http://foo.example" xml:lang="en">
              <n3:stuff xmlns:n3="ftp://example.org"></n3:stuff>
              <n4:stuff xmlns:n4="http://foo.example"></n4:stuff>
            </n1:elem2>
        EOF
        c14n = node2.canonicalize(XML::XML_C14N_EXCLUSIVE_1_0, ["n2"])
        assert_equal(expected, c14n)

        expected = <<~EOF.strip
          <n1:elem2 xmlns:n1="http://example.net" xmlns:n2="http://foo.example" xmlns:n4="http://foo.example" xml:lang="en">
              <n3:stuff xmlns:n3="ftp://example.org"></n3:stuff>
              <n4:stuff></n4:stuff>
            </n1:elem2>
        EOF
        c14n = node2.canonicalize(XML::XML_C14N_EXCLUSIVE_1_0, ["n2", "n4"])
        assert_equal(expected, c14n)

        expected = <<~EOF.strip
          <n1:elem2 xmlns:n1="http://example.net" xmlns:n2="http://foo.example" xmlns:n4="http://foo.example" xml:lang="en" xml:space="retain">
              <n3:stuff xmlns:n3="ftp://example.org"></n3:stuff>
              <n4:stuff></n4:stuff>
            </n1:elem2>
        EOF
        c14n = node2.canonicalize(XML::XML_C14N_1_1)
        assert_equal(expected, c14n)
        assert_raises(RuntimeError) do
          node2.canonicalize(XML::XML_C14N_1_1, ["n2"])
        end
      end

      def test_wrong_params
        xml = "<a><b></b></a>"
        doc = Nokogiri.XML(xml)

        assert_raises(TypeError) { doc.canonicalize(:wrong_type) }
        assert_raises(TypeError) { doc.canonicalize(nil, :wrong_type) }
        doc.canonicalize(nil, nil, :wrong_type)
      end
    end
  end
end
