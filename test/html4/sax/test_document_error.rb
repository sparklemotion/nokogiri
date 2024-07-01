# frozen_string_literal: true

require "helper"

describe Nokogiri::HTML4::SAX do
  describe "callback error handling" do
    def test_error_throwing_document_raises_exception
      custom_sax_handler_class = Class.new(Nokogiri::XML::SAX::Document) do
        def start_document
          raise(StandardError, "parsing did not complete")
        end
      end

      error_parser = Nokogiri::HTML4::SAX::Parser.new(custom_sax_handler_class.new)

      e = assert_raises(StandardError) do
        error_parser.parse("<div>asdf")
      end
      assert_match(/parsing did not complete/, e.message)
    end

    def test_warning_document_encounters_error_but_terminates_normally
      warning_parser = Nokogiri::HTML4::SAX::Parser.new(WarningErrorDocument.new)
      warning_parser.parse("<div")
      refute_empty(warning_parser.document.errors, "error collector did not collect an error")
    end
  end
end
