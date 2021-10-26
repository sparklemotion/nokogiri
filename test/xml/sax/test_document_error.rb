# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    module SAX
      # raises an exception when underlying parser
      # encounters an XML parsing error
      class ThrowingErrorDocument < Document
        def error(msg)
          raise(StandardError, "parsing did not complete: #{msg}")
        end
      end

      # only warns when underlying parser encounters
      # an XML parsing error
      class WarningErrorDocument < Document
        def error(msg)
          errors << msg
        end

        def errors
          @errors ||= []
        end
      end

      class TestErrorHandling < Nokogiri::SAX::TestCase
        def setup
          super
          @error_parser = Parser.new(ThrowingErrorDocument.new)
          @warning_parser = Parser.new(WarningErrorDocument.new)
        end

        def test_error_throwing_document_raises_exception
          @error_parser.parse("<xml>") # no closing element
          fail("#parse should not complete successfully when document #error throws exception")
        rescue StandardError => e
          assert_match(/parsing did not complete/, e.message)
        end

        def test_warning_document_encounters_error_but_terminates_normally
          @warning_parser.parse("<xml>")
          refute_empty(@warning_parser.document.errors, "error collector did not collect an error")
        rescue StandardError => e
          warn(e)
          fail('#parse should complete successfully unless document #error throws exception (#{e}')
        end
      end
    end
  end
end
