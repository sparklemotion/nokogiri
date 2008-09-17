module Nokogiri
  module CSS
    class XPathVisitor
      def visit_class_condition node
        "contains(@class, '#{node.value.first}')"
      end

      def visit_combinator node
        node.value.first.accept(self) + ' and ' +
        node.value.last.accept(self)
      end

      def visit_conditional_selector node
        node.value.first.accept(self) + '[' +
        node.value.last.accept(self) + ']'
      end

      def visit_descendant_selector node
        node.value.first.accept(self) +
        '//' +
        node.value.last.accept(self)
      end

      def visit_child_selector node
        node.value.first.accept(self) +
        '/' +
        node.value.last.accept(self)
      end

      def visit_element_name node
        node.value.first
      end

      def accept node
        node.accept(self)
      end
    end
  end
end
