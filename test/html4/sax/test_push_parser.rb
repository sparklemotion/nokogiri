# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

describe Nokogiri::HTML4::SAX::PushParser do
  let(:parser) { Nokogiri::HTML4::SAX::PushParser.new(Nokogiri::SAX::TestCase::Doc.new) }

  it :test_end_document_called do
    parser << (<<~HTML)
      <p id="asdfasdf">
        <!-- This is a comment -->
        Paragraph 1
      </p>
    HTML
    refute(parser.document.end_document_called)
    parser.finish
    assert(parser.document.end_document_called)
  end

  it :test_start_element do
    parser << (<<~HTML)
      <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
      <html><head><body><p id="asdfasdf">
    HTML

    assert_equal(
      [["html", []], ["head", []], ["body", []], ["p", [["id", "asdfasdf"]]]],
      parser.document.start_elements,
    )

    parser << (<<~HTML)
      <!-- This is a comment -->
      Paragraph 1
      </p></body></html>
    HTML
    assert_equal([" This is a comment "], parser.document.comments)
    parser.finish
  end

  it :test_chevron_partial_html do
    parser << (<<~HTML)
      <p id="asdfasdf">
    HTML

    parser << (<<-HTML)
        <!-- This is a comment -->
        Paragraph 1
      </p>
    HTML
    assert_equal([" This is a comment "], parser.document.comments)
    parser.finish
  end

  it :test_chevron do
    parser << (<<~HTML)
      <p id="asdfasdf">
        <!-- This is a comment -->
        Paragraph 1
      </p>
    HTML
    parser.finish
    assert_equal([" This is a comment "], parser.document.comments)
  end

  it :test_default_options do
    assert_equal(0, parser.options)
  end
end
