# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

module Nokogiri::XML::SAX
  class TestCounter < Nokogiri::XML::SAX::Document
    attr_accessor :context, :lines, :columns

    def initialize
      super
      @context = nil
      @lines   = []
      @columns = []
    end

    def start_element(name, attrs = [])
      @lines << [name, context.line]
      @columns << [name, context.column]
    end
  end

  describe Nokogiri::XML::SAX::ParserContext do
    let(:xml) { <<~XML }
      <hello>

      world
      <inter>
          <net>
          </net>
      </inter>

      </hello>
    XML

    describe "constructors" do
      describe ".new" do
        it "handles IO" do
          ctx = ParserContext.new(StringIO.new("fo"), "UTF-8")
          assert(ctx)
        end

        it "handles String" do
          assert(ParserContext.new("blah blah"))
        end
      end

      it ".file" do
        ctx = ParserContext.file(Nokogiri::TestCase::XML_FILE)
        parser = Parser.new(Nokogiri::SAX::TestCase::Doc.new)
        assert_nil(ctx.parse_with(parser))
      end

      it "graceful_handling_of_invalid_types" do
        assert_raises(TypeError) { ParserContext.new(0xcafecafe) }
        assert_raises(TypeError) { ParserContext.memory(0xcafecafe) }
        assert_raises(TypeError) { ParserContext.io(0xcafecafe) }
        assert_raises(TypeError) { ParserContext.io(0xcafecafe) }
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
        xml = "<root />"
        ctx = ParserContext.new(xml)
        parser = Parser.new(Nokogiri::SAX::TestCase::Doc.new)

        assert_nil(ctx.parse_with(parser))
        assert(parser.document.start_document_called)
        assert(parser.document.end_document_called)
      end
    end

    it "line_numbers" do
      sax_handler = TestCounter.new

      parser = Nokogiri::XML::SAX::Parser.new(sax_handler)
      parser.parse(xml) do |ctx|
        sax_handler.context = ctx
      end

      assert_equal(
        [["hello", 1], ["inter", 4], ["net", 5]],
        sax_handler.lines,
      )
    end

    it "column_numbers" do
      sax_handler = TestCounter.new

      parser = Nokogiri::XML::SAX::Parser.new(sax_handler)
      parser.parse(xml) do |ctx|
        sax_handler.context = ctx
      end

      assert_equal(
        [["hello", 7], ["inter", 7], ["net", 9]],
        sax_handler.columns,
      )
    end

    describe "attributes" do
      it "#replace_entities" do
        pc = ParserContext.new(StringIO.new("<root />"), "UTF-8")
        pc.replace_entities = false

        refute(pc.replace_entities)

        pc.replace_entities = true

        assert(pc.replace_entities)
      end

      it "#recovery" do
        pc = ParserContext.new(StringIO.new("<root />"), "UTF-8")
        pc.recovery = false

        refute(pc.recovery)

        pc.recovery = true

        assert(pc.recovery)
      end
    end
  end
end
