require 'nokogiri/xml/sax'
require 'nokogiri/xml/before_handler'
require 'nokogiri/xml/after_handler'
require 'nokogiri/xml/node'
require 'nokogiri/xml/dtd'
require 'nokogiri/xml/text'
require 'nokogiri/xml/document'
require 'nokogiri/xml/node_set'
require 'nokogiri/xml/xpath'
require 'nokogiri/xml/xpath_context'
require 'nokogiri/xml/builder'
require 'nokogiri/xml/reader'
require 'nokogiri/xml/syntax_error'
require 'nokogiri/xml/notation'

module Nokogiri
  class << self
    def XML thing, url = nil, encoding = nil, options = 1
      Nokogiri::XML.parse(thing, url, encoding, options)
    end
  end

  module XML
    # Parser options
    PARSE_RECOVER     = 1 << 0  # Recover from errors
    PARSE_NOENT       = 1 << 1  # Substitute entities
    PARSE_DTDLOAD     = 1 << 2  # Load external subsets
    PARSE_DTDATTR     = 1 << 3  # Default DTD attributes
    PARSE_DTDVALID    = 1 << 4  # validate with the DTD
    PARSE_NOERROR     = 1 << 5  # suppress error reports
    PARSE_NOWARNING   = 1 << 6  # suppress warning reports
    PARSE_PEDANTIC    = 1 << 7  # pedantic error reporting
    PARSE_NOBLANKS    = 1 << 8  # remove blank nodes
    PARSE_SAX1        = 1 << 9  # use the SAX1 interface internally
    PARSE_XINCLUDE    = 1 << 10 # Implement XInclude substitition
    PARSE_NONET       = 1 << 11 # Forbid network access
    PARSE_NODICT      = 1 << 12 # Do not reuse the context dictionnary
    PARSE_NSCLEAN     = 1 << 13 # remove redundant namespaces declarations
    PARSE_NOCDATA     = 1 << 14 # merge CDATA as text nodes
    PARSE_NOXINCNODE  = 1 << 15 # do not generate XINCLUDE START/END nodes

    class << self
      def parse string_or_io, url = nil, encoding = nil, options = 2159
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
