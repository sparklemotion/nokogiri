# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

module Nokogiri::HTML4::SAX
  describe Nokogiri::HTML4::SAX::ParserContext do
    describe "constructor" do
      describe ".new" do
        it "handles IO" do
          ctx = ParserContext.new(StringIO.new("fo"), "UTF-8")
          assert(ctx)
        end

        it "handles String" do
          ctx = ParserContext.new("blah blah")
          assert(ctx)
        end
      end

      it ".file" do
        ctx = ParserContext.file(Nokogiri::TestCase::HTML_FILE, "UTF-8")
        parser = Parser.new(Nokogiri::SAX::TestCase::Doc.new)
        ctx.parse_with(parser)

        assert(parser.document.start_document_called)
        assert(parser.document.end_document_called)
      end

      it "gracefully handles invalid types" do
        assert_raises(TypeError) { ParserContext.new(0xcafecafe) }
        assert_raises(TypeError) { ParserContext.memory(0xcafecafe) }
        assert_raises(TypeError) { ParserContext.io(0xcafecafe) }
        assert_raises(TypeError) { ParserContext.file(0xcafecafe) }
      end
    end

    describe "#parse_with" do
      it "raises when passed nil" do
        ctx = ParserContext.new("blah")
        assert_raises(ArgumentError) do
          ctx.parse_with(nil)
        end
      end

      it "parses when passed a sax parser" do
        ctx = ParserContext.new("<root/>")
        parser = Parser.new(Nokogiri::SAX::TestCase::Doc.new)

        assert_nil(ctx.parse_with(parser))
        assert(parser.document.start_document_called)
        assert(parser.document.end_document_called)
      end
    end
  end
end
