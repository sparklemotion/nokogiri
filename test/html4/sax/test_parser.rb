# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

module Nokogiri
  module SAX
    class TestCase
      describe Nokogiri::HTML4::SAX::Parser do
        let(:parser) { Nokogiri::HTML4::SAX::Parser.new(Doc.new) }

        it "raises an error on empty content" do
          e = assert_raises(RuntimeError) { parser.parse("") }
          assert_equal("input string cannot be empty", e.message)
        end

        it "parse_empty_file" do
          # Make sure empty files don't break stuff
          empty_file_name = File.join(ASSETS_DIR, "bogus.xml")

          refute_raises do
            parser.parse_file(empty_file_name)
          end
        end

        it "parse_file" do
          parser.parse_file(HTML_FILE)

          # Take a look at the comment in test_parse_document to know
          # a possible reason to this difference.
          if Nokogiri.uses_libxml?
            assert_equal(1111, parser.document.end_elements.length)
          else
            assert_equal(1120, parser.document.end_elements.length)
          end
        end

        it "parse_file_nil_argument" do
          assert_raises(ArgumentError) do
            parser.parse_file(nil)
          end
        end

        it "parse_file_non_existent" do
          assert_raises(Errno::ENOENT) do
            parser.parse_file("there_is_no_reasonable_way_this_file_exists")
          end
        end

        it "parse_file_with_dir" do
          assert_raises(Errno::EISDIR) do
            parser.parse_file(File.dirname(__FILE__))
          end
        end

        it "parse_memory_nil" do
          assert_raises(TypeError) do
            parser.parse_memory(nil)
          end
        end

        describe "encoding" do
          let(:html_encoding_iso8859) { <<~HTML }
            <html><meta charset="ISO-8859-1">
            <body>B\xF6hnhardt</body>
          HTML

          # this input string is really UTF-8 but is marked as ISO-8859-1
          let(:html_encoding_broken) { <<~HTML }
            <html><meta charset="ISO-8859-1">
            <body>Böhnhardt</body>
          HTML

          # this input string is really ISO-8859-1 but is marked as UTF-8
          let(:html_encoding_broken2) { <<~HTML }
            <html><meta charset="UTF-8">
            <body>B\xF6hnhardt</body>
          HTML

          it "is nil by default to indicate encoding should be autodetected" do
            parser = Nokogiri::HTML4::SAX::Parser.new(Doc.new)
            assert_nil(parser.encoding)
          end

          it "can be set in the initializer" do
            assert_equal("UTF-8", Nokogiri::HTML4::SAX::Parser.new(Doc.new, "UTF-8").encoding)
            assert_equal("ISO-2022-JP", Nokogiri::HTML4::SAX::Parser.new(Doc.new, "ISO-2022-JP").encoding)
          end

          it "raises when given an invalid encoding name" do
            assert_raises(ArgumentError) do
              Nokogiri::HTML4::SAX::Parser.new(Doc.new, "not an encoding").parse_io(StringIO.new("<root/>"))
            end
            assert_raises(ArgumentError) do
              Nokogiri::HTML4::SAX::Parser.new(Doc.new, "not an encoding").parse_memory("<root/>")
            end
            assert_raises(ArgumentError) { parser.parse_io(StringIO.new("<root/>"), "not an encoding") }
            assert_raises(ArgumentError) { parser.parse_memory("<root/>", "not an encoding") }
          end

          it "autodetects the encoding if not overridden" do
            parser = Nokogiri::HTML4::SAX::Parser.new(Doc.new)
            parser.parse(html_encoding_iso8859)

            # correctly converted the input ISO-8859-1 to UTF-8 for the callback
            assert_equal("Böhnhardt", parser.document.data.join.strip)
          end

          it "overrides the ISO-8859-1 document's encoding when set via initializer" do
            parser = Nokogiri::HTML4::SAX::Parser.new(Doc.new)
            parser.parse_memory(html_encoding_broken)

            assert_equal("BÃ¶hnhardt", parser.document.data.join.strip)

            parser = Nokogiri::HTML4::SAX::Parser.new(Doc.new, "UTF-8")
            parser.parse_memory(html_encoding_broken)

            assert_equal("Böhnhardt", parser.document.data.join.strip)
          end

          it "overrides the UTF-8 document's encoding when set via initializer" do
            if Nokogiri.uses_libxml?(">= 2.13.0") # nekohtml is a better guesser than libxml2
              parser = Nokogiri::HTML4::SAX::Parser.new(Doc.new)
              parser.parse_memory(html_encoding_broken2)

              assert(parser.document.errors.any? { |e| e.match(/Invalid byte/) })
            end

            parser = Nokogiri::HTML4::SAX::Parser.new(Doc.new)
            parser.parse_memory(html_encoding_broken2, "ISO-8859-1")

            assert_equal("Böhnhardt", parser.document.data.join.strip)
            refute(parser.document.errors.any? { |e| e.match(/Invalid byte/) })
          end

          it "can be set via parse_io" do
            if Nokogiri.uses_libxml?("< 2.13.0")
              skip("older libxml2 encoding detection is sus")
            end

            parser = Nokogiri::HTML4::SAX::Parser.new(Doc.new)
            parser.parse_io(StringIO.new(html_encoding_broken), "UTF-8")

            assert_equal("Böhnhardt", parser.document.data.join.strip)

            parser = Nokogiri::HTML4::SAX::Parser.new(Doc.new)
            parser.parse_io(StringIO.new(html_encoding_broken2), "ISO-8859-1")

            assert_equal("Böhnhardt", parser.document.data.join.strip)
          end

          it "can be set via parse_memory" do
            parser = Nokogiri::HTML4::SAX::Parser.new(Doc.new)
            parser.parse_memory(html_encoding_broken, "UTF-8")

            assert_equal("Böhnhardt", parser.document.data.join.strip)

            parser = Nokogiri::HTML4::SAX::Parser.new(Doc.new)
            parser.parse_memory(html_encoding_broken2, "ISO-8859-1")

            assert_equal("Böhnhardt", parser.document.data.join.strip)
          end
        end

        it "parse_document" do
          parser.parse_memory(<<~HTML)
            <p>Paragraph 1</p>
            <p>Paragraph 2</p>
          HTML

          # JRuby version is different because of the internal implementation
          # JRuby version uses NekoHTML which inserts empty "head" elements.
          #
          # Currently following features are set:
          # "http://cyberneko.org/html/properties/names/elems" => "lower"
          # "http://cyberneko.org/html/properties/names/attrs" => "lower"
          if Nokogiri.uses_libxml?
            assert_equal(
              [["html", []], ["body", []], ["p", []], ["p", []]],
              parser.document.start_elements,
            )
          else
            assert_equal(
              [["html", []], ["head", []], ["body", []], ["p", []], ["p", []]],
              parser.document.start_elements,
            )
          end
        end

        it "parser_attributes" do
          html = <<~eohtml
            <html>
              <head>
                <title>hello</title>
              </head>
            <body>
              <img src="face.jpg" title="daddy &amp; me">
              <hr noshade size="2">
            </body>
            </html>
          eohtml

          block_called = false
          parser.parse(html) do |ctx|
            block_called = true
            ctx.replace_entities = true
          end

          assert(block_called)

          noshade_value = ["noshade", nil]

          assert_equal(
            [
              ["html", []],
              ["head", []],
              ["title", []],
              ["body", []],
              ["img", [
                ["src", "face.jpg"],
                ["title", "daddy & me"],
              ],],
              ["hr", [
                noshade_value,
                ["size", "2"],
              ],],
            ],
            parser.document.start_elements,
          )
        end

        let(:html_with_br_tag) { <<~HTML }
          <html>
            <head></head>
            <body>
              <div>
                hello
                <br>
              </div>

              <div>
                hello again
              </div>
            </body>
          </html>
        HTML

        it "parsing_dom_error_from_string" do
          parser.parse(html_with_br_tag)
          assert_equal(6, parser.document.start_elements.length)
        end

        it "parsing_dom_error_from_io" do
          parser.parse(StringIO.new(html_with_br_tag))
          assert_equal(6, parser.document.start_elements.length)
        end

        it "empty_processing_instruction" do
          # https://github.com/sparklemotion/nokogiri/issues/845
          refute_raises do
            parser.parse_memory("<strong>this will segfault<?strong>")
          end
        end

        it "handles invalid types gracefully" do
          assert_raises(TypeError) { Nokogiri::HTML4::SAX::Parser.new.parse(0xcafecafe) }
          assert_raises(TypeError) { Nokogiri::HTML4::SAX::Parser.new.parse_memory(0xcafecafe) }
          assert_raises(TypeError) { Nokogiri::HTML4::SAX::Parser.new.parse_io(0xcafecafe) }
        end
      end
    end
  end
end
