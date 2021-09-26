# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

class Nokogiri::SAX::TestCase
  describe Nokogiri::XML::SAX::PushParser do
    let(:parser) { Nokogiri::XML::SAX::PushParser.new(Doc.new) }

    it :test_exception do
      assert_raises(Nokogiri::XML::SyntaxError) do
        parser << "<foo /><foo />"
      end

      assert_raises(Nokogiri::XML::SyntaxError) do
        parser << nil
      end
    end

    it :test_early_finish do
      parser << "<foo>"
      assert_raises(Nokogiri::XML::SyntaxError) do
        parser.finish
      end
    end

    it :test_write_last_chunk do
      parser << "<foo>"
      parser.write("</foo>", true)
      assert_equal [["foo", []]], parser.document.start_elements
      assert_equal [["foo"]], parser.document.end_elements
    end

    it :test_empty_doc do
      parser.options |= Nokogiri::XML::ParseOptions::RECOVER
      parser.write("", true)
      assert_nil parser.document.start_elements
      assert_nil parser.document.end_elements
    end

    it :test_finish_should_rethrow_last_error do
      expected = assert_raise(Nokogiri::XML::SyntaxError) { parser << "</foo>" }
      actual = assert_raise(Nokogiri::XML::SyntaxError) { parser.finish }
      assert_equal actual.message, expected.message
    end

    it :test_should_throw_error_returned_by_document do
      doc = Doc.new
      class << doc
        def error(msg)
          raise "parse error"
        end
      end
      parser = Nokogiri::XML::SAX::PushParser.new(doc)

      exception = assert_raise(RuntimeError) { parser << "</foo>" }
      assert_equal exception.message, "parse error"
    end

    it :test_writing_nil do
      assert_equal parser.write(nil), parser
    end

    it :test_end_document_called do
      parser.<<(<<~EOF)
        <p id="asdfasdf">
          <!-- This is a comment -->
          Paragraph 1
        </p>
      EOF
      assert !parser.document.end_document_called
      parser.finish
      assert parser.document.end_document_called
    end

    it :test_start_element do
      parser.<<(<<~EOF)
        <p id="asdfasdf">
      EOF

      assert_equal [["p", [["id", "asdfasdf"]]]],
        parser.document.start_elements

      parser.<<(<<~EOF)
          <!-- This is a comment -->
          Paragraph 1
        </p>
      EOF
      assert_equal [" This is a comment "], parser.document.comments
      parser.finish
    end

    it :test_start_element_with_namespaces do
      parser.<<(<<~EOF)
        <p xmlns:foo="http://foo.example.com/">
      EOF

      assert_equal [["p", [["xmlns:foo", "http://foo.example.com/"]]]],
        parser.document.start_elements

      parser.<<(<<~EOF)
          <!-- This is a comment -->
          Paragraph 1
        </p>
      EOF
      assert_equal [" This is a comment "], parser.document.comments
      parser.finish
    end

    it :test_start_element_ns do
      parser.<<(<<~EOF)
        <stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0' size='large'></stream:stream>
      EOF

      assert_equal 1, parser.document.start_elements_namespace.length
      el = parser.document.start_elements_namespace.first

      assert_equal "stream", el.first
      assert_equal 2, el[1].length
      assert_equal [["version", "1.0"], ["size", "large"]],
        el[1].map { |x| [x.localname, x.value] }

      assert_equal "stream", el[2]
      assert_equal "http://etherx.jabber.org/streams", el[3]
      parser.finish
    end

    it :test_end_element_ns do
      parser.<<(<<~EOF)
        <stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'></stream:stream>
      EOF

      assert_equal [["stream", "stream", "http://etherx.jabber.org/streams"]],
        parser.document.end_elements_namespace
      parser.finish
    end

    it :test_chevron_partial_xml do
      parser.<<(<<~EOF)
        <p id="asdfasdf">
      EOF

      parser.<<(<<~EOF)
          <!-- This is a comment -->
          Paragraph 1
        </p>
      EOF
      assert_equal [" This is a comment "], parser.document.comments
      parser.finish
    end

    it :test_chevron do
      parser.<<(<<~EOF)
        <p id="asdfasdf">
          <!-- This is a comment -->
          Paragraph 1
        </p>
      EOF
      parser.finish
      assert_equal [" This is a comment "], parser.document.comments
    end

    it :test_default_options do
      assert_equal 0, parser.options
    end

    it :test_recover do
      parser.options |= Nokogiri::XML::ParseOptions::RECOVER
      parser.<<(<<~EOF)
        <p>
          Foo
          <bar>
          Bar
        </p>
      EOF
      parser.finish
      assert(parser.document.errors.size >= 1)
      assert_equal [["p", []], ["bar", []]], parser.document.start_elements
      assert_equal "FooBar", parser.document.data.map { |x|
        x.gsub(/\s/, "")
      }.join
    end

    it :test_broken_encoding do
      skip_unless_libxml2("ultra hard to fix for pure Java version")
      parser.options |= Nokogiri::XML::ParseOptions::RECOVER
      # This is ISO_8859-1:
      parser.<< "<?xml version='1.0' encoding='UTF-8'?><r>Gau\337</r>"
      parser.finish
      assert(parser.document.errors.size >= 1)
      assert_equal "Gau\337", parser.document.data.join
      assert_equal [["r"]], parser.document.end_elements
    end

    it :test_replace_entities_attribute_behavior do
      if Nokogiri.uses_libxml?
        # initially false
        assert_equal false, parser.replace_entities

        # can be set to true
        parser.replace_entities = true
        assert_equal true, parser.replace_entities

        # can be set to false
        parser.replace_entities = false
        assert_equal false, parser.replace_entities
      else
        # initially true
        assert_equal true, parser.replace_entities

        # ignore attempts to set to false
        parser.replace_entities = false # TODO: should we raise an exception here?
        assert_equal true, parser.replace_entities
      end
    end

    it :test_untouched_entities do
      skip_unless_libxml2("entities are always replaced in pure Java version")
      parser.<<(<<~EOF)
        <p id="asdf&amp;asdf">
          <!-- This is a comment -->
          Paragraph 1 &amp; 2
        </p>
      EOF
      parser.finish
      assert_equal [["p", [["id", "asdf&#38;asdf"]]]], parser.document.start_elements
      assert_equal "Paragraph 1 & 2", parser.document.data.join.strip
    end

    it :test_replaced_entities do
      parser.replace_entities = true
      parser.<<(<<~EOF)
        <p id="asdf&amp;asdf">
          <!-- This is a comment -->
          Paragraph 1 &amp; 2
        </p>
      EOF
      parser.finish
      assert_equal [["p", [["id", "asdf&asdf"]]]], parser.document.start_elements
      assert_equal "Paragraph 1 & 2", parser.document.data.join.strip
    end
  end
end
