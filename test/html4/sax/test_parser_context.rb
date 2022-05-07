# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

module Nokogiri
  module HTML
    module SAX
      class TestParserContext < Nokogiri::SAX::TestCase
        def test_from_io
          ctx = ParserContext.new(StringIO.new("fo"), "UTF-8")
          assert(ctx)
        end

        def test_from_string
          ctx = ParserContext.new("blah blah")
          assert(ctx)
        end

        def test_parse_with
          ctx = ParserContext.new("blah")
          assert_raises(ArgumentError) do
            ctx.parse_with(nil)
          end
        end

        def test_parse_with_sax_parser
          # assert_nothing_raised do
          xml = "<root />"
          ctx = ParserContext.new(xml)
          parser = Parser.new(Doc.new)
          ctx.parse_with(parser)
          # end
        end

        def test_from_file
          # assert_nothing_raised do
          ctx = ParserContext.file(HTML_FILE, "UTF-8")
          parser = Parser.new(Doc.new)
          ctx.parse_with(parser)
          # end
        end

        def test_graceful_handling_of_invalid_types
          assert_raises(TypeError) { ParserContext.new(0xcafecafe) }
          assert_raises(TypeError) { ParserContext.memory(0xcafecafe, "UTF-8") }
          assert_raises(TypeError) { ParserContext.io(0xcafecafe, 1) }
          assert_raises(TypeError) { ParserContext.io(StringIO.new("asdf"), "should be an index into ENCODINGS") }
          assert_raises(TypeError) { ParserContext.file(0xcafecafe, "UTF-8") }
          assert_raises(TypeError) { ParserContext.file("path/to/file", 0xcafecafe) }
        end
      end
    end
  end
end
