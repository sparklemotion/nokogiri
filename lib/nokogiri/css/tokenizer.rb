module Nokogiri
  module CSS
    class Tokenizer < GeneratedTokenizer
      ###
      # Scan and tokenize +str+
      def scan(str)
        scan_evaluate(str)
      end
    end
  end
end
