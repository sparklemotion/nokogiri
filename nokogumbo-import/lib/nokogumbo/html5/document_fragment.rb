require 'nokogiri'

module Nokogiri
  module HTML5
    class DocumentFragment < Nokogiri::HTML::DocumentFragment
      # Create a document fragment.
      def initialize(doc, tags = nil, ctx = nil, options = {})
        return self unless tags
        if ctx
          raise Argument.new("Fragment parsing with context not supported")
        else
          tags = Nokogiri::HTML5.read_and_encode(tags, nil)

          # Copied from Nokogiri's document_fragment.rb and labled "a horrible
          # hack."
          if tags.strip =~ /^<body/i
            path = "/html/body"
          else
            path = "/html/body/node()"
          end
          temp_doc = HTML5.parse("<!DOCTYPE html><html><body>#{tags}", options)
          temp_doc.xpath(path).each { |child| child.parent = self }
        self.errors = temp_doc.errors
        end
      end

      # Parse a document fragment from +tags+, returning a Nodeset.
      def self.parse(tags, encoding = nil, options = {})
        doc = HTML5::Document.new
        tags = HTML5.read_and_encode(tags, encoding)
        doc.encoding = 'UTF-8'
        new(doc, tags, nil, options)
      end
    end
  end
end
