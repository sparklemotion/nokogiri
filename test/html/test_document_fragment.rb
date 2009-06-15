require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module HTML
    class TestDocumentFragment < Nokogiri::TestCase
      def setup
        super
        @html = Nokogiri::HTML.parse(File.read(HTML_FILE), HTML_FILE)
      end

      def test_new
        fragment = Nokogiri::HTML::DocumentFragment.new(@html)
      end

      def test_fragment_should_have_document
        fragment = Nokogiri::HTML::DocumentFragment.new(@html)
        assert_equal @html, fragment.document
      end

      def test_name
        fragment = Nokogiri::HTML::DocumentFragment.new(@html)
        assert_equal '#document-fragment', fragment.name
      end

      def test_static_method
        fragment = Nokogiri::HTML::DocumentFragment.parse("<div>a</div>")
        assert_instance_of Nokogiri::HTML::DocumentFragment, fragment
      end

      def test_many_fragments
        100.times { Nokogiri::HTML::DocumentFragment.new(@html) }
      end

      def test_subclass
        klass = Class.new(Nokogiri::HTML::DocumentFragment)
        fragment = klass.new(@html, "<div>a</div>")
        assert_instance_of klass, fragment
      end

      def test_html_fragment
        fragment = Nokogiri::HTML.fragment("<div>a</div>")
        assert_equal "<div>a</div>", fragment.to_s
      end

      def test_html_fragment_has_outer_text
        doc = "a<div>b</div>c"
        fragment = Nokogiri::HTML::Document.new.fragment(doc)
        if Nokogiri::VERSION_INFO['libxml']['loaded'] <= "2.6.16"
          assert_equal "a<div>b</div><p>c</p>", fragment.to_s
        else
          assert_equal "a<div>b</div>c", fragment.to_s
        end
      end

      def test_html_fragment_case_insensitivity
        doc = "<crazyDiv>b</crazyDiv>"
        fragment = Nokogiri::HTML::Document.new.fragment(doc)
        assert_equal "<crazydiv>b</crazydiv>", fragment.to_s
      end

      def test_html_fragment_with_leading_whitespace
        doc = "     <div>b</div>  "
        fragment = Nokogiri::HTML::Document.new.fragment(doc)
        assert_equal "<div>b</div>", fragment.to_s
      end

      def test_to_s
        doc = "<span>foo<br></span><span>bar</span>"
        fragment = Nokogiri::HTML::Document.new.fragment(doc)
        assert_equal "<span>foo<br></span><span>bar</span>", fragment.to_s
      end

      def test_to_html
        doc = "<span>foo<br></span><span>bar</span>"
        fragment = Nokogiri::HTML::Document.new.fragment(doc)
        assert_equal "<span>foo<br></span><span>bar</span>", fragment.to_html
      end

      def test_to_xhtml
        doc = "<span>foo<br></span><span>bar</span>"
        fragment = Nokogiri::HTML::Document.new.fragment(doc)
        if Nokogiri::VERSION_INFO['libxml']['loaded'] >= "2.7.0"
          assert_equal "<span>foo<br /></span><span>bar</span>", fragment.to_xhtml
        else
          assert_equal "<span>foo<br></span><span>bar</span>", fragment.to_xhtml
        end
      end

      def test_to_xml
        doc = "<span>foo<br></span><span>bar</span>"
        fragment = Nokogiri::HTML::Document.new.fragment(doc)
        assert_equal "<span>foo<br/></span><span>bar</span>", fragment.to_xml
      end

      def test_fragment_script_tag_with_cdata
        doc = HTML::Document.new
        fragment = doc.fragment("<script>var foo = 'bar';</script>")
        assert_equal("<script>var foo = 'bar';</script>",
          fragment.to_s)
      end

      def test_fragment_with_comment
        doc = HTML::Document.new
        fragment = doc.fragment("<p>hello<!-- your ad here --></p>")
        assert_equal("<p>hello<!-- your ad here --></p>",
          fragment.to_s)
      end

    end
  end
end
