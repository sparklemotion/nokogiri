module Nokogiri
  module CSS
    class Parser < GeneratedParser
      class << self
        def parse string
          new.parse(string)
        end
      end

      def initialize
        @tokenizer = Tokenizer.new
      end

      def parse string
        @tokenizer.scan string
        do_parse
      end

      def next_token
        @tokenizer.next_token
      end
    end
  end
end
