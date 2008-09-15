module Nokogiri
  module XML
    class Builder
      attr_accessor :doc
      def initialize
        @doc = Nokogiri::XML::Document.new
      end

      def method_missing(method, *args, &block)
        node = Nokogiri::XML::Node.new(method.to_s) { |n|
          n.content = args.first
        }
        @doc.root = node
      end
    end
  end
end
