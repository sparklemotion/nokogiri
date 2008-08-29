require 'nokogiri/xml/node'
require 'nokogiri/xml/document'
require 'nokogiri/xml/node_set'
require 'nokogiri/xml/text_node'

module Nokogiri
  module XML
    class << self
      def parse(string, url = nil, encoding = nil, options = 1)
        Document.wrap(DL::XML.xmlReadMemory(
                                  string,
                                  string.length,
                                  DL::XML.dl2? ? (url || 0) : url,
                                  DL::XML.dl2? ? (encoding || 0) : encoding,
                                  options
                                 ))
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
