# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  # Translate a CSS selector into an XPath 1.0 query
  module CSS
    class << self
      # TODO: Deprecate this method ahead of 2.0 and delete it in 2.0.
      # It is not used by Nokogiri and shouldn't be part of the public API.
      def parse(selector) # :nodoc:
        warn("Nokogiri::CSS.parse is deprecated and will be removed in a future version of Nokogiri. Use Nokogiri::CSS::Parser#parse instead.", uplevel: 1, category: :deprecated)
        Parser.new.parse(selector)
      end

      # :call-seq:
      #   xpath_for(selector_list) → Array<String>
      #   xpath_for(selector_list [, prefix:] [, visitor:] [, ns:]) → Array<String>
      #
      # Translate a CSS selector list to the equivalent XPath expressions.
      #
      # 💡 Note that translated queries are cached by default for performance concerns.
      #
      # ⚠ Users should prefer Nokogiri::XML::Searchable#css, which is mixed into all document and
      # node classes, for querying documents with CSS selectors. This method is the underlying
      # mechanism used by XML::Searchable and is provided solely for advanced users to translate
      # \CSS selectors to XPath directly.
      #
      # Also see Nokogiri::XML::Searchable#css for documentation on supported CSS selector features,
      # some extended syntax that Nokogiri supports, and advanced CSS features like pseudo-class
      # functions.
      #
      # [Parameters]
      # - +selector_list+ (String)
      #
      #   The CSS selector to be translated into XPath. This is always a String, but that string
      #   value may be a {selector list}[https://www.w3.org/TR/selectors-4/#grouping] (see
      #   examples).
      #
      # - +prefix:+ (String)
      #
      #   The XPath expression prefix which determines the search context. See Nokogiri::XML::XPath
      #   for standard options. Default is +XPath::GLOBAL_SEARCH_PREFIX+.
      #
      # - +visitor:+ (Nokogiri::CSS::XPathVisitor)
      #
      #   The visitor class to use to transform the AST into XPath. Default is
      #   +Nokogiri::CSS::XPathVisitor.new+. See Nokogiri::CSS::XPathVisitor for more information on
      #   some of the complex behavior that can be customized for your document type.
      #
      # - +ns:+ (Hash<String ⇒ String>)
      #
      #   Namespaces that are referenced in the query, if any. This is a hash where the keys are the
      #   namespace prefix and the values are the namespace URIs. Default is an empty Hash.
      #
      # [Returns] (Array<String>) The equivalent set of XPath expressions for +selector_list+
      #
      # *Example* with a simple selector:
      #
      #   Nokogiri::CSS.xpath_for("div") # => ["//div"]
      #
      # *Example* with a compound selector:
      #
      #   Nokogiri::CSS.xpath_for("div.xl") # => ["//div[contains(concat(' ',normalize-space(@class),' '),' xl ')]"]
      #
      # *Example* with a complex selector:
      #
      #   Nokogiri::CSS.xpath_for("h1 + div") # => ["//h1/following-sibling::*[1]/self::div"]
      #
      # *Example* with a selector list:
      #
      #   Nokogiri::CSS.xpath_for("h1, h2, h3") # => ["//h1", "//h2", "//h3"]
      #
      def xpath_for(selector, options = {})
        raise TypeError, "no implicit conversion of #{selector.inspect} to String" unless selector.respond_to?(:to_str)

        selector = selector.to_str
        raise Nokogiri::CSS::SyntaxError, "empty CSS selector" if selector.empty?

        if options.key?(:prefix) && options.key?(:visitor)
          raise ArgumentError, "cannot provide both :prefix and :visitor"
        end

        ns = options.fetch(:ns, {})

        visitor = if options.key?(:prefix)
          Nokogiri::CSS::XPathVisitor.new(prefix: options.fetch(:prefix))
        elsif options.key?(:visitor)
          options.fetch(:visitor)
        else
          Nokogiri::CSS::XPathVisitor.new
        end

        Parser.new(ns).xpath_for(selector, visitor)
      end
    end
  end
end

require_relative "css/node"
require_relative "css/xpath_visitor"
x = $-w
$-w = false
require_relative "css/parser"
$-w = x

require_relative "css/tokenizer"
require_relative "css/syntax_error"
