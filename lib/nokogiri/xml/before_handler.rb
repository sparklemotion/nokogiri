module Nokogiri
  module XML
    class BeforeHandler < Nokogiri::XML::SAX::Document # :nodoc:
      def initialize node, original_html
        @original_html = original_html
        @node = node
        @document = node.document
        @stack = []
      end

      def start_element name, attrs = []
        return unless @original_html =~ /<#{name}/i
        node = Node.new(name, @document)
        Hash[*attrs].each do |k,v|
          node[k] = v
        end
        node.parent = @stack.last if @stack.length != 0
        @stack << node
      end

      def characters string
        node = @stack.last
        node.content += string
      end

      def end_element name
        return unless @original_html =~ /<#{name}/i
        @node.add_previous_sibling @stack.last if @stack.length == 1
        @stack.pop
      end
    end
  end
end
