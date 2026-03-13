# frozen_string_literal: true

module Nokogiri
  module XML
    module XPath
      # The XPath search prefix to search globally, +//+
      GLOBAL_SEARCH_PREFIX = "//"

      # The XPath search prefix to search direct descendants of the root element, +/+
      ROOT_SEARCH_PREFIX = "/"

      # The XPath search prefix to search direct descendants of the current element, +./+
      CURRENT_SEARCH_PREFIX = "./"

      # The XPath search prefix to search anywhere in the current element's subtree, +.//+
      SUBTREE_SEARCH_PREFIX = ".//"

      # TODO: document me
      def self.expression(expr)
        Nokogiri::XML::XPath::Expression.new(expr)
      end
    end
  end
end

require_relative "xpath/syntax_error"
