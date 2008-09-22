module Nokogiri
  module XML
    class AfterHandler < BeforeHandler
      attr_accessor :after_nodes

      def initialize node, original_html
        super
        @after_nodes = []
      end

      def end_element name
        return unless @original_html =~ /<#{name}/i
        @after_nodes << @stack.last if @stack.length == 1
        @stack.pop
      end
    end
  end
end
