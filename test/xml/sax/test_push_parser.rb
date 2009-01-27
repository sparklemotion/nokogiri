require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', "helper"))

module Nokogiri
  module XML
    module SAX
      class TestPushParser < Nokogiri::SAX::TestCase
        def setup
          @parser = XML::SAX::PushParser.new(Doc.new)
        end

        def test_chevron
          @parser.<<(<<-eoxml)
            <p id="asdfasdf">
              <!-- This is a comment -->
              Paragraph 1
            </p>
          eoxml
          assert_equal [' This is a comment '], @parser.document.comments
        end
      end
    end
  end
end
