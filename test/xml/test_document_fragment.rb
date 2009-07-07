require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestDocumentFragment < Nokogiri::TestCase
      def setup
        super
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
      end

      def test_new
        fragment = Nokogiri::XML::DocumentFragment.new(@xml)
      end

      def test_fragment_should_have_document
        fragment = Nokogiri::XML::DocumentFragment.new(@xml)
        assert_equal @xml, fragment.document
      end

      def test_name
        fragment = Nokogiri::XML::DocumentFragment.new(@xml)
        assert_equal '#document-fragment', fragment.name
      end

      def test_static_method
        fragment = Nokogiri::XML::DocumentFragment.parse("<div>a</div>")
        assert_instance_of Nokogiri::XML::DocumentFragment, fragment
      end

      def test_many_fragments
        100.times { Nokogiri::XML::DocumentFragment.new(@xml) }
      end

      def test_subclass
        klass = Class.new(Nokogiri::XML::DocumentFragment)
        fragment = klass.new(@xml, "<div>a</div>")
        assert_instance_of klass, fragment
      end

      def test_subclass_parse
        klass = Class.new(Nokogiri::XML::DocumentFragment)
        doc = klass.parse("<div>a</div>")
        assert_instance_of klass, doc
      end

      def test_xml_fragment
        fragment = Nokogiri::XML.fragment("<div>a</div>")
        assert_equal "<div>a</div>", fragment.to_s
      end

      def test_xml_fragment_has_multiple_toplevel_children
        # TODO: this is lame. xml fragment() should support multiple top-level children
        doc = "<div>b</div><div>e</div>"
        fragment = Nokogiri::XML::Document.new.fragment(doc)
        assert_equal "<div>b</div>", fragment.to_s
      end

      def test_xml_fragment_has_outer_text
        # this test is descriptive, not prescriptive.
        doc = "a<div>b</div>"
        fragment = Nokogiri::XML::Document.new.fragment(doc)
        assert_equal "", fragment.to_s

        doc = "<div>b</div>c"
        fragment = Nokogiri::XML::Document.new.fragment(doc)
        assert_equal "<div>b</div>", fragment.to_s
      end

      def test_xml_fragment_case_sensitivity
        doc = "<crazyDiv>b</crazyDiv>"
        fragment = Nokogiri::XML::Document.new.fragment(doc)
        assert_equal "<crazyDiv>b</crazyDiv>", fragment.to_s
      end

      def test_xml_fragment_with_leading_whitespace
        doc = "     <div>b</div>  "
        fragment = Nokogiri::XML::Document.new.fragment(doc)
        assert_equal "<div>b</div>", fragment.to_s
      end

      def test_xml_fragment_with_leading_whitespace_and_newline
        doc = "     \n<div>b</div>  "
        fragment = Nokogiri::XML::Document.new.fragment(doc)
        assert_equal "<div>b</div>", fragment.to_s
      end
    end
  end
end
