# frozen_string_literal: true

module Nokogiri
  module CSS
    class Parser < Racc::Parser # :nodoc:
      # Create a new CSS parser with respect to +namespaces+
      def initialize(selector, ns: nil)
        @selector = selector
        @namespaces = ns
        @tokenizer = Tokenizer.new

        super()
      end

      def parse
        @tokenizer.scan_setup(@selector)
        do_parse
      end

      def next_token
        @tokenizer.next_token
      end

      # Get the xpath for +string+ using +options+
      def xpath(visitor)
        parse.map do |ast|
          ast.to_xpath(visitor)
        end
      end

      # On CSS parser error, raise an exception
      def on_error(error_token_id, error_value, value_stack)
        after = value_stack.compact.last
        raise SyntaxError, "unexpected '#{error_value}' after '#{after}'"
      end
    end
  end
end
