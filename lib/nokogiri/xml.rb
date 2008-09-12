require 'nokogiri/xml/node'
require 'nokogiri/xml/document'
require 'nokogiri/xml/node_set'
require 'nokogiri/xml/text_node'
require 'nokogiri/xml/xpath'

module Nokogiri
  module XML
    class << self
      def parse(string, url = nil, encoding = nil, options = 1)
        Document.read_memory(string, url, encoding, options)
      end

      def substitute_entities=(value = true)
        DL::XML.xmlSubstituteEntitiesDefault(value ? 1 : 0)
      end

      def load_external_subsets=(value = true)
        DL::XML::LOAD_EXT_DTD.value = value ? 1 : 0
      end
    end
  end
end
