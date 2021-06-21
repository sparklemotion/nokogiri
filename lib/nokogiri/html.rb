# frozen_string_literal: true
require_relative "html4"

module Nokogiri
  HTML = Nokogiri::HTML4

  # @!method HTML(input, url = nil, encoding = nil, options = XML::ParseOptions::DEFAULT_HTML, &block)
  # Parse HTML. Convenience method for Nokogiri::HTML4::Document.parse
  # @!scope class
  define_singleton_method(:HTML, Nokogiri.method(:HTML4))

  # @note This module/namespace is an alias for {Nokogiri::HTML4} as of v1.12.0. Before v1.12.0,
  #   {Nokogiri::HTML4} did not exist, and this was the module/namespace for all HTML-related
  #   classes.
  module HTML
    # @note This class is an alias for {Nokogiri::HTML4::Document} as of v1.12.0.
    class Document < Nokogiri::XML::Document
    end

    # @note This class is an alias for {Nokogiri::HTML4::DocumentFragment} as of v1.12.0.
    class DocumentFragment < Nokogiri::XML::DocumentFragment
    end

    # @note This class is an alias for {Nokogiri::HTML4::Builder} as of v1.12.0.
    class Builder < Nokogiri::XML::Builder
    end

    module SAX
      # @note This class is an alias for {Nokogiri::HTML4::SAX::Parser} as of v1.12.0.
      class Parser < Nokogiri::XML::SAX::Parser
      end

      # @note This class is an alias for {Nokogiri::HTML4::SAX::ParserContext} as of v1.12.0.
      class ParserContext < Nokogiri::XML::SAX::ParserContext
      end

      # @note This class is an alias for {Nokogiri::HTML4::SAX::PushParser} as of v1.12.0.
      class PushParser
      end
    end
  end
end
