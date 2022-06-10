# frozen_string_literal: true

module Nokogiri
  module XML
    class Text < Nokogiri::XML::CharacterData
      def content=(string)
        self.native_content = string.to_s
      end

      ###
      # The method is required to remove double spaces, leading and trailing whitespace.
      # Returns nil if the text was not found
      def process_text
        result = self.text.gsub(/[[:space:]]+/, ' ').strip
        result.empty? ? nil : result
      end

      ###
      # Similar to process_text except that if no text was found, it will return raise(NoFoundText.new).
      def process_text!
        process_text || raise(NoFoundText.new)
      end

      ###
      # Empty text processing class.
      class NoFoundText < RuntimeError
        def message
          "Text wasn't found in the node"
        end
      end
    end
  end
end
