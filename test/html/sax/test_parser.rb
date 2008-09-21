require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', "helper"))

module Nokogiri
  module HTML
    module SAX
      class TestParser < Nokogiri::SAX::TestCase
        def setup
          @parser = HTML::SAX::Parser.new(Doc.new)
        end

        def test_parse_file
          @parser.parse_file(HTML_FILE)
          assert_equal 1110, @parser.document.end_elements.length
        end

        def test_parse_document
          @parser.parse_memory(<<-eoxml)
            <p>Paragraph 1</p>
            <p>Paragraph 2</p>
          eoxml
          assert_equal([["html", []], ["body", []], ["p", []], ["p", []]],
                       @parser.document.start_elements)
        end
      end
    end
  end
end
