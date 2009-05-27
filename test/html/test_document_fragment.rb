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
    end
  end
end
