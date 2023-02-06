# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

module Nokogiri
  module HTML
    module SAX
      class TestParser < Nokogiri::SAX::TestCase
        def setup
          super
          @parser = Nokogiri::HTML4::SAX::Parser.new(Doc.new)
        end

        def test_parse_empty_document
          # This caused a segfault in libxml 2.6.x
          assert_nil(@parser.parse(""))
        end

        def test_parse_empty_file
          # Make sure empty files don't break stuff
          empty_file_name = File.join(ASSETS_DIR, "bogus.xml")
          @parser.parse_file(empty_file_name) # assert_nothing_raised
        end

        def test_parse_file
          @parser.parse_file(HTML_FILE)

          # Take a look at the comment in test_parse_document to know
          # a possible reason to this difference.
          if Nokogiri.uses_libxml?
            assert_equal(1111, @parser.document.end_elements.length)
          else
            assert_equal(1120, @parser.document.end_elements.length)
          end
        end

        def test_parse_file_nil_argument
          assert_raises(ArgumentError) do
            @parser.parse_file(nil)
          end
        end

        def test_parse_file_non_existant
          assert_raises(Errno::ENOENT) do
            @parser.parse_file("there_is_no_reasonable_way_this_file_exists")
          end
        end

        def test_parse_file_with_dir
          assert_raises(Errno::EISDIR) do
            @parser.parse_file(File.dirname(__FILE__))
          end
        end

        def test_parse_memory_nil
          assert_raises(TypeError) do
            @parser.parse_memory(nil)
          end
        end

        def test_parse_force_encoding
          @parser.parse_memory(<<-HTML, "UTF-8")
          <meta http-equiv="Content-Type" content="text/html; charset=windows-1251">
          Информация
          HTML
          assert_equal(
            "Информация",
            @parser.document.data.join.strip,
          )
        end

        def test_parse_document
          @parser.parse_memory(<<-eoxml)
            <p>Paragraph 1</p>
            <p>Paragraph 2</p>
          eoxml

          # JRuby version is different because of the internal implementation
          # JRuby version uses NekoHTML which inserts empty "head" elements.
          #
          # Currently following features are set:
          # "http://cyberneko.org/html/properties/names/elems" => "lower"
          # "http://cyberneko.org/html/properties/names/attrs" => "lower"
          if Nokogiri.uses_libxml?
            assert_equal(
              [["html", []], ["body", []], ["p", []], ["p", []]],
              @parser.document.start_elements,
            )
          else
            assert_equal(
              [["html", []], ["head", []], ["body", []], ["p", []], ["p", []]],
              @parser.document.start_elements,
            )
          end
        end

        def test_parser_attributes
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
          @parser.parse(html) do |ctx|
            block_called = true
            ctx.replace_entities = true
          end

          assert(block_called)

          noshade_value = if Nokogiri.uses_libxml?("< 2.7.7")
            ["noshade", "noshade"]
          else
            ["noshade", nil]
          end

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
            @parser.document.start_elements,
          )
        end

        HTML_WITH_BR_TAG = <<-EOF
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
        EOF

        def test_parsing_dom_error_from_string
          @parser.parse(HTML_WITH_BR_TAG)
          assert_equal(6, @parser.document.start_elements.length)
        end

        def test_parsing_dom_error_from_io
          @parser.parse(StringIO.new(HTML_WITH_BR_TAG))
          assert_equal(6, @parser.document.start_elements.length)
        end

        def test_empty_processing_instruction
          @parser.parse_memory("<strong>this will segfault<?strong>")
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
