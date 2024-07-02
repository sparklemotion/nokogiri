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
      # Probably I'm doing something wrong, but I can't make nekohtml report errors,
      # despite setting http://cyberneko.org/html/features/report-errors.
      # See https://nekohtml.sourceforge.net/settings.html for more info.
      # I'd love some help here if someone finds this comment and cares enough to dig in.
      skip_unless_libxml2("nekohtml sax parser does not seem to report errors?")

      warning_parser = Nokogiri::HTML4::SAX::Parser.new(Nokogiri::SAX::TestCase::Doc.new)
      warning_parser.parse("<html><body><<div att=")
      refute_empty(warning_parser.document.errors, "error collector did not collect an error")
    end
  end
end
