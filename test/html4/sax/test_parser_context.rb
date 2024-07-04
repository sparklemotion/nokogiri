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

      describe "encoding" do
        # this input string is really ISO-8859-1 but is marked as UTF-8
        let(:html_encoding_broken2) { <<~HTML }
          <html><meta charset="UTF-8">
          <body>B\xF6hnhardt</body>
        HTML

        it "gracefully handles nonsense encodings" do
          assert_raises(ArgumentError) do
            ParserContext.io(StringIO.new("asdf"), "not-an-encoding")
          end
          assert_raises(ArgumentError) do
            ParserContext.memory("asdf", "not-an-encoding")
          end
          assert_raises(ArgumentError) do
            ParserContext.file(Nokogiri::TestCase::XML_FILE, "not-an-encoding")
          end
        end

        describe ".io" do
          it "supports passing encoding name" do
            pc = ParserContext.io(StringIO.new(html_encoding_broken2), "ISO-8859-1")
            parser = Parser.new(Nokogiri::SAX::TestCase::Doc.new)
            pc.parse_with(parser)

            assert_equal("Böhnhardt", parser.document.data.join.strip)
          end

          it "supports passing Encoding" do
            pc = ParserContext.io(StringIO.new(html_encoding_broken2), Encoding::ISO_8859_1)
            parser = Parser.new(Nokogiri::SAX::TestCase::Doc.new)
            pc.parse_with(parser)

            assert_equal("Böhnhardt", parser.document.data.join.strip)
          end

          it "supports passing libxml2 encoding id" do
            enc = nil
            assert_output(nil, /deprecated/) do
              enc = Parser::ENCODINGS["ISO-8859-1"]
            end

            pc = nil
            assert_output(nil, /deprecated/) do
              pc = ParserContext.io(StringIO.new(html_encoding_broken2), enc)
            end

            parser = Parser.new(Nokogiri::SAX::TestCase::Doc.new)
            pc.parse_with(parser)

            assert_equal("Böhnhardt", parser.document.data.join.strip)
          end
        end

        describe ".memory" do
          it "supports passing encoding name" do
            pc = ParserContext.memory(html_encoding_broken2, "ISO-8859-1")
            parser = Parser.new(Nokogiri::SAX::TestCase::Doc.new)
            pc.parse_with(parser)

            assert_equal("Böhnhardt", parser.document.data.join.strip)
          end

          it "supports passing Encoding" do
            pc = ParserContext.memory(html_encoding_broken2, Encoding::ISO_8859_1)
            parser = Parser.new(Nokogiri::SAX::TestCase::Doc.new)
            pc.parse_with(parser)

            assert_equal("Böhnhardt", parser.document.data.join.strip)
          end
        end

        describe ".file" do
          let(:file) do
            Tempfile.new.tap do |f|
              f.write html_encoding_broken2
              f.close
            end
          end

          it "supports passing encoding name" do
            pc = ParserContext.file(file.path, "ISO-8859-1")
            parser = Parser.new(Nokogiri::SAX::TestCase::Doc.new)
            pc.parse_with(parser)

            assert_equal("Böhnhardt", parser.document.data.join.strip)
          end

          it "supports passing Encoding" do
            pc = ParserContext.file(file.path, Encoding::ISO_8859_1)
            parser = Parser.new(Nokogiri::SAX::TestCase::Doc.new)
            pc.parse_with(parser)

            assert_equal("Böhnhardt", parser.document.data.join.strip)
          end
        end
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
