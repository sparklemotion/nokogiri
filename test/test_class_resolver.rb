# frozen_string_literal: true

require "helper"

describe Nokogiri::ClassResolver do
  it "resolves related classes through anonymous subclasses" do
    cases = [
      [Nokogiri::XML::Document, "DocumentFragment", Nokogiri::XML::DocumentFragment],
      [Nokogiri::HTML4::Document, "DocumentFragment", Nokogiri::HTML4::DocumentFragment],
      [Nokogiri::XML::Builder, "Document", Nokogiri::XML::Document],
      [Nokogiri::HTML4::Builder, "Document", Nokogiri::HTML4::Document],
      [Nokogiri::XML::SAX::Parser, "ParserContext", Nokogiri::XML::SAX::ParserContext],
      [Nokogiri::HTML4::SAX::Parser, "ParserContext", Nokogiri::HTML4::SAX::ParserContext],
    ]
    if defined?(Nokogiri::HTML5)
      cases << [Nokogiri::HTML5::Document, "DocumentFragment", Nokogiri::HTML5::DocumentFragment]
      cases << [Nokogiri::HTML5::Builder, "Document", Nokogiri::HTML5::Document]
    end

    cases.each do |base, class_name, expected|
      subclass = Class.new(base)
      assert_equal(expected, subclass.new.related_class(class_name))
      assert_equal(expected, Class.new(subclass).new.related_class(class_name))
    end
  end

  it "returns nil when an anonymous class has no related class" do
    subclass = Class.new { include Nokogiri::ClassResolver }
    assert_nil(subclass.new.related_class("DocumentFragment"))
  end

  describe Nokogiri::XML::Node do
    it "finds the right things" do
      assert_equal(
        Nokogiri::XML::DocumentFragment,
        Nokogiri::XML::Document.new.related_class("DocumentFragment"),
      )
      assert_equal(
        Nokogiri::HTML4::DocumentFragment,
        Nokogiri::HTML4::Document.new.related_class("DocumentFragment"),
      )
      if defined?(Nokogiri::HTML5)
        assert_equal(
          Nokogiri::HTML5::DocumentFragment,
          Nokogiri::HTML5::Document.new.related_class("DocumentFragment"),
        )
      end
    end
  end

  describe Nokogiri::XML::Builder do
    it "finds the right things" do
      assert_equal(
        Nokogiri::XML::Document,
        Nokogiri::XML::Builder.new.related_class("Document"),
      )
      assert_equal(
        Nokogiri::HTML4::Document,
        Nokogiri::HTML4::Builder.new.related_class("Document"),
      )
      if defined?(Nokogiri::HTML5)
        assert_equal(
          Nokogiri::HTML5::Document,
          Nokogiri::HTML5::Builder.new.related_class("Document"),
        )
      end
    end
  end

  describe Nokogiri::XML::SAX::Parser do
    it "finds the right things" do
      assert_equal(
        Nokogiri::XML::SAX::ParserContext,
        Nokogiri::XML::SAX::Parser.new.related_class("ParserContext"),
      )
      assert_equal(
        Nokogiri::HTML4::SAX::ParserContext,
        Nokogiri::HTML4::SAX::Parser.new.related_class("ParserContext"),
      )
    end
  end
end
