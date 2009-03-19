require 'nokogiri/html/entity_lookup'
require 'nokogiri/html/document'
require 'nokogiri/html/sax/parser'

module Nokogiri
  class << self
    ###
    # Parse HTML.  +thing+ may be a String, or any object that
    # responds to _read_ and _close_ such as an IO, or StringIO.
    # +url+ is resource where this document is located.  +encoding+ is the
    # encoding that should be used when processing the document. +options+
    # is a number that sets options in the parser, such as
    # Nokogiri::XML::PARSE_RECOVER.  See the constants in
    # Nokogiri::XML.
    def HTML thing, url = nil, encoding = nil, options = 2145
      Nokogiri::HTML.parse(thing, url, encoding, options)
    end
  end

  module HTML
    # Parser options
    PARSE_NOERROR   = 1 << 5  # No error reports
    PARSE_NOWARNING = 1 << 6  # No warnings 
    PARSE_PEDANTIC  = 1 << 7  # Pedantic errors
    PARSE_NOBLANKS  = 1 << 8  # Remove blanks nodes
    PARSE_NONET     = 1 << 11 # No network access

    class << self
      ###
      # Parse HTML.  See Nokogiri.HTML.
      def parse string_or_io, url = nil, encoding = nil, options = 2145
        if string_or_io.respond_to?(:encoding)
          encoding ||= string_or_io.encoding.name
        end

        if string_or_io.respond_to?(:read)
          url ||= string_or_io.respond_to?(:path) ? string_or_io.path : nil
          return Document.read_io(string_or_io, url, encoding, options)
        end

        return Document.new if(string_or_io.length == 0)
        Document.read_memory(string_or_io, url, encoding, options)
      end

      ####
      # Parse a fragment from +string+ in to a NodeSet.
      def fragment string
        doc = parse(string)
        fragment = XML::DocumentFragment.new(doc)
        finder = lambda { |c, f|
          c.each do |child|
            if string == child.content && child.name == 'text'
              fragment.add_child(child)
            end
            fragment.add_child(child) if string =~ /<#{child.name}/
          end
          return fragment if fragment.children.length > 0

          c.each do |child|
            finder.call(child.children, f)
          end
        }
        finder.call(doc.children, finder)
        fragment
      end
    end
    NamedCharacters = EntityLookup.new
  end
end
