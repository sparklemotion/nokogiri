module Nokogiri
  module XML
    class Builder
      def initialize
        @doc = Nokogiri::XML::Document.new
      end

      def method_missing(method, *args, &block)
        node = Nokogiri::XML::Node.new(method.to_s)
        node.content = args.first
      end
    end
  end
end
