# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

module Nokogiri
  module HTML
    module SAX
      class TestPushParser < Nokogiri::SAX::TestCase
        def setup
          super
          @parser = HTML::SAX::PushParser.new(Doc.new)
        end

        def test_end_document_called
          @parser.<<(<<~eoxml)
            <p id="asdfasdf">
              <!-- This is a comment -->
              Paragraph 1
            </p>
          eoxml
          assert(!@parser.document.end_document_called)
          @parser.finish
          assert(@parser.document.end_document_called)
        end

        def test_start_element
          @parser.<<(<<~eoxml)
            <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
            <html><head><body><p id="asdfasdf">
          eoxml

          assert_equal([["html", []], ["head", []], ["body", []], ["p", [["id", "asdfasdf"]]]],
            @parser.document.start_elements)

          @parser.<<(<<~eoxml)
            <!-- This is a comment -->
            Paragraph 1
            </p></body></html>
          eoxml
          assert_equal([' This is a comment '], @parser.document.comments)
          @parser.finish
        end

        def test_chevron_partial_html
          @parser.<<(<<~eoxml)
            <p id="asdfasdf">
          eoxml

          @parser.<<(<<-eoxml)
              <!-- This is a comment -->
              Paragraph 1
            </p>
          eoxml
          assert_equal([' This is a comment '], @parser.document.comments)
          @parser.finish
        end

        def test_chevron
          @parser.<<(<<~eoxml)
            <p id="asdfasdf">
              <!-- This is a comment -->
              Paragraph 1
            </p>
          eoxml
          @parser.finish
          assert_equal([' This is a comment '], @parser.document.comments)
        end

        def test_default_options
          assert_equal(0, @parser.options)
        end
      end
    end
  end
end
