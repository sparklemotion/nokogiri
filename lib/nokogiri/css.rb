require 'nokogiri/css/node'
require 'nokogiri/css/xpath_visitor'
require 'nokogiri/css/generated_parser'
require 'nokogiri/css/generated_tokenizer'
require 'nokogiri/css/tokenizer'
require 'nokogiri/css/parser'
require 'nokogiri/css/syntax_error'
require 'nokogiri/css/selector_handler'

module Nokogiri
  module CSS
    class << self
      ###
      # Parse this CSS selector in +selector+.  Returns an AST.
      def parse selector
        Parser.new.parse selector
      end

      ###
      # Get the XPath for +selector+.
      def xpath_for selector, options={}
        Parser.new.xpath_for selector, options
      end
    end
  end
end
