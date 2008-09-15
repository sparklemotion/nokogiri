module Nokogiri
  module HTML
    class Builder < XML::Builder
      def initialize(&block)
        @doc = Nokogiri::HTML::Document.new
        @node_stack = []
        instance_eval(&block)
      end
    end
  end
end
