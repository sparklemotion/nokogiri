# frozen_string_literal: true
module Nokogiri
  class << self
    ###
    # Parse HTML. Convenience method for Nokogiri::HTML4::Document.parse
    def HTML4(input, url = nil, encoding = nil, options = XML::ParseOptions::DEFAULT_HTML, &block)
      Nokogiri::HTML4::Document.parse(input, url, encoding, options, &block)
    end
  end

  # @since v1.12.0
  # @note Before v1.12.0, {Nokogiri::HTML4} did not exist, and {Nokogiri::HTML} was the module/namespace for parsing HTML.
  module HTML4
    class << self
      ###
      # Parse HTML. Convenience method for Nokogiri::HTML4::Document.parse
      def parse(input, url = nil, encoding = nil, options = XML::ParseOptions::DEFAULT_HTML, &block)
        Document.parse(input, url, encoding, options, &block)
      end

      ####
      # Parse a fragment from +string+ in to a NodeSet.
      def fragment(string, encoding = nil)
        HTML4::DocumentFragment.parse(string, encoding)
      end
    end

    # Instance of Nokogiri::HTML4::EntityLookup
    NamedCharacters = EntityLookup.new
  end
end

require_relative "html4/entity_lookup"
require_relative "html4/document"
require_relative "html4/document_fragment"
require_relative "html4/sax/parser_context"
require_relative "html4/sax/parser"
require_relative "html4/sax/push_parser"
require_relative "html4/element_description"
require_relative "html4/element_description_defaults"
