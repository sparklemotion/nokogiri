module Nokogiri
  module CSS
    class Parser < GeneratedTokenizer
      class << self
        def parse string
          new.parse(string)
        end
        def parse_to_xpath string, options={}
          new.parse_to_xpath(string, options)
        end
      end
      alias :parse :scan_str

      def parse_to_xpath string, options={}
        prefix = options[:prefix] || nil
        visitor = options[:visitor] || nil
        args = [prefix, visitor]
        parse(string).map {|ast| ast.to_xpath(prefix, visitor)}
      end

      def on_error error_token_id, error_value, value_stack
        after = value_stack.compact.last
        raise SyntaxError.new("unexpected '#{error_value}' after '#{after}'")
      end
    end
  end
end
