# frozen_string_literal: true

module Nokogiri
  module XML
    class Namespace
      include Nokogiri::XML::PP::Node
      attr_reader :document

      # Returns true if this is a Namespace
      def namespace?
        true
      end

      private

      def inspect_attributes
        [:prefix, :href]
      end
    end
  end
end
