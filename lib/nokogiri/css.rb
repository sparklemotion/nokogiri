require 'nokogiri/css/node'
require 'nokogiri/css/xpath_visitor'
require 'nokogiri/css/generated_parser'
require 'nokogiri/css/generated_tokenizer'
require 'nokogiri/css/tokenizer'
require 'nokogiri/css/parser'
require 'nokogiri/css/syntax_error'

module Nokogiri
  module CSS
    class << self
      def parse string
        Parser.new.parse string
      end
      def parse_to_xpath string, options={}
        Parser.new.parse_to_xpath string, options
      end
    end
  end
end
