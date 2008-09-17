module Nokogiri
  module CSS
    class Tokenizer < GeneratedTokenizer
      def scan(str)
        scan_evaluate(str)
      end
    end
  end
end
