# frozen_string_literal: true

require "helper"

module Nokogiri
  class TestCase
    describe Nokogiri do
      def test_libxml_iconv
        skip_unless_libxml2("this constant is only set in the C extension when libxml2 is used")
        assert(Nokogiri.const_defined?(:LIBXML_ICONV_ENABLED))
      end

      def test_parse_with_io
        doc = Nokogiri.parse(StringIO.new("<html><head><title></title><body></body></html>"))
        assert_instance_of(Nokogiri::HTML4::Document, doc)
      end

      def test_xml?
        doc = Nokogiri.parse(File.read(XML_FILE))
        assert_predicate(doc, :xml?)
        refute_predicate(doc, :html?)
      end

      def test_atom_is_xml?
        doc = Nokogiri.parse(File.read(XML_ATOM_FILE))
        assert_predicate(doc, :xml?)
        refute_predicate(doc, :html?)
      end

      def test_html?
        doc = Nokogiri.parse(File.read(HTML_FILE))
        refute_predicate(doc, :xml?)
        assert_predicate(doc, :html?)
      end

      def test_nokogiri_method_with_html
        doc1 = Nokogiri(File.read(HTML_FILE))
        doc2 = Nokogiri.parse(File.read(HTML_FILE))
        assert_equal(doc1.serialize, doc2.serialize)
      end

      def test_nokogiri_method_with_block
        root = Nokogiri { b("bold tag") }
        assert_instance_of(Nokogiri::HTML4::Document, root.document)
        assert_equal("<b>bold tag</b>", root.to_html.chomp)
      end

      def test_make_with_html
        root = Nokogiri.make("<b>bold tag</b>")
        assert_instance_of(Nokogiri::HTML4::Document, root.document)
        assert_equal("<b>bold tag</b>", root.to_html.chomp)
      end

      def test_make_with_block
        doc = Nokogiri.make { b("bold tag") }
        assert_equal("<b>bold tag</b>", doc.to_html.chomp)
      end

      def test_no_hardcoded_paths
        skip("only relevant in precompiled gem") unless Nokogiri::VERSION_INFO.dig("libxml", "precompiled")
        skip("C-ext is not stripped on aarch64-mingw-ucrt and so contains hardcoded paths in debug info") if RUBY_PLATFORM == "aarch64-mingw-ucrt"

        cext_fname = $LOADED_FEATURES.grep(/\/\d.\d\/nokogiri./).first
        refute_nil(cext_fname, "the C-ext should be loaded")
        cext_text = File.binread(cext_fname)
        assert_match(/Init_nokogiri/, cext_text, "C-ext shoud contain the init function")
        refute_match(/usr\/local/, cext_text, "there should be no rpath to /usr/local/rake-compiler/ruby/x86_64-unknown-linux-musl/ruby-3.4.5/lib or so")
        refute_match(/home\//, cext_text, "there should be no path to /home/ or so")
      end
    end
  end
end
