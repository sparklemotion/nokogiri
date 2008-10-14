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
  class << self
    def XML thing, url = nil, encoding = nil, options = 1
      Nokogiri::XML.parse(thing, url, encoding, options)
    end
  end

  module XML
    class << self
      def parse string_or_io, url = nil, encoding = nil, options = 1
        if string_or_io.respond_to?(:read)
          url ||= string_or_io.respond_to?(:path) ? string_or_io.path : nil
          string_or_io = string_or_io.read
        end

        # read_memory pukes on empty docs
        return Document.new if string_or_io.nil? or string_or_io.empty?

        Document.read_memory(string_or_io, url, encoding, options)
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
