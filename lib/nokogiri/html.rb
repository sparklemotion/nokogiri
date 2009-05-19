require 'nokogiri/html/entity_lookup'
require 'nokogiri/html/document'
require 'nokogiri/html/sax/parser'
require 'nokogiri/html/element_description'

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
    def HTML thing, url = nil, encoding = nil, options = 2145, &block
      Nokogiri::HTML.parse(thing, url, encoding, options, &block)
    end
  end

  module HTML
    class << self
      ###
      # Parse HTML.  See Nokogiri.HTML.
      def parse string_or_io, url = nil, encoding = nil, options = 2145, &block

        options = Nokogiri::XML::ParseOptions.new(options) if Fixnum === options
        # Give the options to the user
        yield options if block_given?

        if string_or_io.respond_to?(:encoding)
          encoding ||= string_or_io.encoding.name
        end

        if string_or_io.respond_to?(:read)
          url ||= string_or_io.respond_to?(:path) ? string_or_io.path : nil
          return Document.read_io(string_or_io, url, encoding, options.to_i)
        end

        return Document.new if(string_or_io.length == 0)
        Document.read_memory(string_or_io, url, encoding, options.to_i)
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

    # Instance of Nokogiri::HTML::EntityLookup
    NamedCharacters = EntityLookup.new
  end
end
