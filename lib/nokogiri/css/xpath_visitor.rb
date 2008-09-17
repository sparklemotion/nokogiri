module Nokogiri
  module CSS
    class XPathVisitor
      def initialize
        @xpath = '//'
      end

      def visit_sac_child_selector node
        @xpath += node.value.first.accept(self) + "/" +
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
