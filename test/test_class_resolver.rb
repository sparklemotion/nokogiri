# frozen_string_literal: true

require "helper"

describe Nokogiri::ClassResolver do
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
