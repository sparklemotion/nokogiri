# frozen_string_literal: true

module Nokogiri
  module XML
    class Text < Nokogiri::XML::CharacterData
      def content=(string)
        self.native_content = string.to_s
      end

      def process_text
        result = self.text.gsub(/[[:space:]]+/, ' ').strip
        result.empty? ? nil : result
      end

      def process_text!
        process_text || raise(NoFoundText.new)
      end

      def message
        "Text wasn't found in the node"
      end
    end
  end
end
