require 'nokogiri/xml/sax'
require 'nokogiri/xml/before_handler'
require 'nokogiri/xml/after_handler'
require 'nokogiri/xml/node'
require 'nokogiri/xml/text'
require 'nokogiri/xml/document'
require 'nokogiri/xml/node_set'
require 'nokogiri/xml/xpath'
require 'nokogiri/xml/xpath_context'
require 'nokogiri/xml/builder'
require 'nokogiri/xml/reader'
require 'nokogiri/xml/syntax_error'

module Nokogiri
  module XML
    class << self
      def parse(string, url = nil, encoding = nil, options = 1)
        return Document.new if string.nil? or string.empty? # read_memory pukes on empty docs
        Document.read_memory(string, url, encoding, options)
      end

      def substitute_entities=(value = true)
        Document.substitute_entities = value
      end

      def load_external_subsets=(value = true)
        Document.load_external_subsets = value
      end
    end
  end
end
