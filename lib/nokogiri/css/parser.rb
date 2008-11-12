module Nokogiri
  module CSS
    class Parser < GeneratedTokenizer
      class << self
        def parse string
          new.parse(string)
        end
      end
      alias :parse :scan_str

      def on_error error_token_id, error_value, value_stack
        after = value_stack.compact.last
        raise SyntaxError.new("unexpected '#{error_value}' after '#{after}'")
      end
    end
  end
end
