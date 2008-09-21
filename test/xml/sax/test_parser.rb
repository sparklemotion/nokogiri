require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', "helper"))

module Nokogiri
  module XML
    module SAX
      class TestParser < Nokogiri::TestCase
        class Doc
          attr_reader :start_elements, :start_document_called
          def start_document
            @start_document_called = true
          end

          def start_element *args
            (@start_elements ||= []) << args
          end
        end

        def setup
          @parser = XML::SAX::Parser.new(Doc.new)
        end

        def test_start_document
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">Paragraph 1</p>
          eoxml
          assert @parser.document.start_document_called
        end

        def test_start_element_attrs
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">Paragraph 1</p>
          eoxml
          assert_equal [["p", ["id", "asdfasdf"]]],
                       @parser.document.start_elements
        end

        def test_parse_document
          @parser.parse_memory(<<-eoxml)
            <p>Paragraph 1</p>
            <p>Paragraph 2</p>
          eoxml
        end
      end
    end
  end
end
