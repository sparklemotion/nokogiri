# frozen_string_literal: true
module Nokogiri
  module CSS
    class << self
      ###
      # Parse this CSS selector in +selector+.  Returns an AST.
      def parse(selector)
        Parser.new.parse(selector)
      end

      ###
      # Get the XPath for +selector+.
      def xpath_for(selector, options = {})
        Parser.new(options[:ns] || {}).xpath_for(selector, options)
      end
    end
  end
end

require_relative "css/node"
require_relative "css/xpath_visitor"
x = $-w
$-w = false
require_relative "css/parser"
$-w = x

require_relative "css/tokenizer"
require_relative "css/syntax_error"
