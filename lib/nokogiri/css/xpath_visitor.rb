module Nokogiri
  module CSS
    class XPathVisitor
      def initialize
        @xpath = '//'
      end

      def visit_descendant_selector node
        node.value.first.accept(self)
        @xpath += '/*/'
        node.value.last.accept(self)
      end

      def visit_child_selector node
        node.value.first.accept(self)
        @xpath += '/'
        node.value.last.accept(self)
      end

      def visit_element_name node
        @xpath += node.value.first
      end

      def accept node
        node.accept(self)
      end
    end
  end
end
