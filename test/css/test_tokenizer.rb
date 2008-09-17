require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module CSS
    class TestTokenizer < Nokogiri::TestCase
      def setup
        @scanner = Nokogiri::CSS::Tokenizer.new
      end

      def test_scan_greater
        @scanner.scan('x > y')
        assert_tokens([ [:IDENT, 'x'],
                        [:GREATER, ' >'],
                        [:S, ' '],
                        [:IDENT, 'y']
        ], @scanner)
      end

      def assert_tokens(tokens, scanner)
        toks = []
        while tok = @scanner.next_token
          toks << tok
        end
        assert_equal(tokens.length, toks.length)
        assert_equal(tokens, toks)
      end
    end
  end
end
