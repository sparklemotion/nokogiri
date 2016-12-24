# -*- coding: utf-8 -*-
require "helper"

module Nokogiri
  module HTML
    module SAX
      class TestParserCharacters < Nokogiri::SAX::TestCase
        class TextDoc < Doc
          def strip_characters_calls
            @calls.each do |call|
              method = call.keys.first
              args   = call.values.first
              if method == :characters
                args.each do |arg|
                  arg.strip!
                end
              end
            end
          end
        end

        def setup
          super
          @doc    = TextDoc.new
          @parser = HTML::SAX::Parser.new @doc
        end

        def test_parser_text_order
          html = <<-eohtml
            <html>
              <head>
                <title>title</title>
              </head>
              <body>
                text 0
                <p>
                  text 1
                  <span>text 2</span>
                  text 3
                </p>
                text 4
                <p>
                  text 5
                  <span>text 6</span>
                  text 7
                </p>
                text 8
              </body>
            </html>
          eohtml

          @parser.parse html
          @doc.strip_characters_calls
          calls = @doc.select_calls [:start_element, :end_element, :characters]

          assert_equal [
            {:start_element => ["html", []]},
            {:start_element => ["head", []]},
            {:start_element => ["title", []]},
            {:characters    => ["title"]},
            {:end_element   => ["title"]},
            {:end_element   => ["head"]},
            {:start_element => ["body", []]},

            {:characters    => ["text 0"]},
            {:start_element => ["p", []]},
            {:characters    => ["text 1"]},
            {:start_element => ["span", []]},
            {:characters    => ["text 2"]},
            {:end_element   => ["span"]},
            {:characters    => ["text 3"]},
            {:end_element   => ["p"]},

            {:characters    => ["text 4"]},

            {:start_element => ["p", []]},
            {:characters    => ["text 5"]},
            {:start_element => ["span", []]},
            {:characters    => ["text 6"]},
            {:end_element   => ["span"]},
            {:characters    => ["text 7"]},
            {:end_element   => ["p"]},
            {:characters    => ["text 8"]},

            {:end_element => ["body"]},
            {:end_element => ["html"]}
          ], calls
        end
      end
    end
  end
end
