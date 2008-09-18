module Nokogiri
  module CSS
    class XPathVisitor
      def visit_function node
        return 'child::text()' if node.value.first == 'text('
        node.value.first + ')'
      end

      def visit_preceding_selector node
        node.value.last.accept(self) +
          '[preceding-sibling:' +
          node.value.first.accept(self) +
          ']'
      end

      def visit_id node
        node.value.first =~ /^#(.*)$/
        "@id = '#{$1}'"
      end

      def visit_attribute_condition node
        attribute = node.value.first.type == :FUNCTION ? '' : '@'
        attribute += node.value.first.accept(self)

        # Support non-standard css
        attribute.gsub!(/^@@/, '@')

        return attribute unless node.value.length == 3

        value = node.value.last
        value = "'#{value}'" if value !~ /^['"]/

        case node.value[1]
        when '*='
          "contains(#{attribute}, #{value})"
        when '$='
          "substring(#{attribute}, string-length(#{attribute}) - " +
            "string-length(#{value}) + 1, string-length(#{value})) = #{value}"
        else
          attribute + " #{node.value[1]} " + "#{value}"
        end
      end

      def visit_pseudo_class node
        '1 = 1' # Ignore pseudo classes for now
      end

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
