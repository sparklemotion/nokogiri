# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

module Nokogiri
  module SAX
    class TestCase
      describe Nokogiri::HTML4::SAX::Parser do
        let(:parser) { Nokogiri::HTML4::SAX::Parser.new(Doc.new) }

        it "parse_empty_document" do
          # This caused a segfault in libxml 2.6.x
          assert_nil(parser.parse(""))
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

        it "parse_force_encoding" do
          parser.parse_memory(<<-HTML, "UTF-8")
          <meta http-equiv="Content-Type" content="text/html; charset=windows-1251">
          Информация
          HTML
          assert_equal(
            "Информация",
            parser.document.data.join.strip,
          )
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
