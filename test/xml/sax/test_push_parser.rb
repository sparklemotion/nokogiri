# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

describe Nokogiri::XML::SAX::PushParser do
  let(:parser) { Nokogiri::XML::SAX::PushParser.new(Nokogiri::SAX::TestCase::Doc.new) }

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
    parser.finish

    assert_nil(parser.document.start_elements)
    assert_nil(parser.document.end_elements)
    if Nokogiri.jruby?
      assert_empty(parser.document.errors)
    elsif Nokogiri.uses_libxml?(">= 2.12.0") # gnome/libxml2@53050b1d
      assert_match(/Document is empty/, parser.document.errors.first)
    end
    assert(parser.document.end_document_called)
  end

  it :test_empty_doc_without_recovery do
    # behavior is different between implementations
    # https://github.com/sparklemotion/nokogiri/issues/1758
    if Nokogiri.jruby?
      parser.finish

      assert_nil(parser.document.start_elements)
      assert_nil(parser.document.end_elements)
      assert_empty(parser.document.errors)
      assert(parser.document.end_document_called)
    else
      e = assert_raises(Nokogiri::XML::SyntaxError) do
        parser.finish
      end
      if Nokogiri.uses_libxml?(">= 2.12.0") # gnome/libxml2@53050b1d
        assert_match(/Document is empty/, e.message)
      end
    end
  end

  it :test_finish_should_rethrow_last_error do
    expected = assert_raises(Nokogiri::XML::SyntaxError) { parser << "</foo>" }
    actual = assert_raises(Nokogiri::XML::SyntaxError) { parser.finish }
    assert_equal actual.message, expected.message
  end

  it :test_should_throw_error_returned_by_document do
    doc = Nokogiri::SAX::TestCase::Doc.new
    class << doc
      def error(msg)
        raise "parse error"
      end
    end
    parser = Nokogiri::XML::SAX::PushParser.new(doc)

    exception = assert_raises(RuntimeError) { parser << "</foo>" }
    assert_equal("parse error", exception.message)
  end

  it :test_writing_nil do
    assert_equal parser.write(nil), parser
  end

  it :test_end_document_called do
    parser << (<<~XML)
      <p id="asdfasdf">
        <!-- This is a comment -->
        Paragraph 1
      </p>
    XML
    refute parser.document.end_document_called
    parser.finish
    assert parser.document.end_document_called
  end

  it :test_start_element do
    parser << (<<~XML)
      <p id="asdfasdf">
    XML

    assert_equal [["p", [["id", "asdfasdf"]]]],
      parser.document.start_elements

    parser << (<<~XML)
        <!-- This is a comment -->
        Paragraph 1
      </p>
    XML
    assert_equal [" This is a comment "], parser.document.comments
    parser.finish
  end

  it :test_start_element_with_namespaces do
    parser << (<<~XML)
      <p xmlns:foo="http://foo.example.com/">
    XML

    assert_equal [["p", [["xmlns:foo", "http://foo.example.com/"]]]],
      parser.document.start_elements

    parser << (<<~XML)
        <!-- This is a comment -->
        Paragraph 1
      </p>
    XML
    assert_equal [" This is a comment "], parser.document.comments
    parser.finish
  end

  it :test_start_element_ns do
    parser << (<<~XML)
      <stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0' size='large'></stream:stream>
    XML

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
    parser << (<<~XML)
      <stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'></stream:stream>
    XML

    assert_equal [["stream", "stream", "http://etherx.jabber.org/streams"]],
      parser.document.end_elements_namespace
    parser.finish
  end

  it :test_chevron_partial_xml do
    parser << (<<~XML)
      <p id="asdfasdf">
    XML

    parser << (<<~XML)
        <!-- This is a comment -->
        Paragraph 1
      </p>
    XML
    assert_equal [" This is a comment "], parser.document.comments
    parser.finish
  end

  it :test_chevron do
    parser << (<<~XML)
      <p id="asdfasdf">
        <!-- This is a comment -->
        Paragraph 1
      </p>
    XML
    parser.finish
    assert_equal [" This is a comment "], parser.document.comments
  end

  it :test_default_options do
    assert_equal 0, parser.options
  end

  it :test_recover do
    parser.options |= Nokogiri::XML::ParseOptions::RECOVER
    parser << (<<~XML)
      <p>
        Foo
        <bar>
        Bar
      </p>
    XML
    parser.finish
    assert_operator(parser.document.errors.size, :>=, 1)
    assert_equal [["p", []], ["bar", []]], parser.document.start_elements
    assert_equal "FooBar", parser.document.data.map { |x|
      x.gsub(/\s/, "")
    }.join
  end

  it :test_broken_encoding do
    skip_unless_libxml2("ultra hard to fix for pure Java version")

    parser.options |= Nokogiri::XML::ParseOptions::RECOVER
    # This is ISO_8859-1:
    parser << "<?xml version='1.0' encoding='UTF-8'?><r>Gau\337</r>"
    parser.finish

    assert_operator(parser.document.errors.size, :>=, 1)

    # the interpretation of the byte may vary by libxml2 version in recovery mode
    # see for example https://gitlab.gnome.org/GNOME/libxml2/-/issues/598
    assert(parser.document.data.join.start_with?("Gau"))

    assert_equal [["r"]], parser.document.end_elements
  end

  it :test_replace_entities_attribute_behavior do
    if Nokogiri.uses_libxml?
      # initially false
      refute parser.replace_entities

      # can be set to true
      parser.replace_entities = true
      assert parser.replace_entities

      # can be set to false
      parser.replace_entities = false
      refute parser.replace_entities
    else
      # initially true
      assert parser.replace_entities

      # ignore attempts to set to false
      parser.replace_entities = false # TODO: should we raise an exception here?
      assert parser.replace_entities
    end
  end

  it :test_untouched_entities do
    skip_unless_libxml2("entities are always replaced in pure Java version")
    parser << (<<~XML)
      <p id="asdf&amp;asdf">
        <!-- This is a comment -->
        Paragraph 1 &amp; 2
      </p>
    XML
    parser.finish
    assert_equal [["p", [["id", "asdf&#38;asdf"]]]], parser.document.start_elements
    assert_equal "Paragraph 1 & 2", parser.document.data.join.strip
  end

  it :test_replaced_entities do
    parser.replace_entities = true
    parser << (<<~XML)
      <p id="asdf&amp;asdf">
        <!-- This is a comment -->
        Paragraph 1 &amp; 2
      </p>
    XML
    parser.finish
    assert_equal [["p", [["id", "asdf&asdf"]]]], parser.document.start_elements
    assert_equal "Paragraph 1 & 2", parser.document.data.join.strip
  end
end
