module Nokogiri
  module CSS
    class XPathVisitor
      def visit_function node
        case node.value.first
        when /^text\(/
          'child::text()'
        when /^nth-child\(/
          'position() = ' + node.value[1] # TODO: think this needs to be fixed. see test cases.
        when /^(eq|nth|nth-of-type)\(/
          # TODO: ick. clean this up.
          if node.value[1].is_a?(Nokogiri::CSS::Node) and node.value[1].type == :AN_PLUS_B
            if node.value[1].value[0] == 'even'
              "(position() mod 2) = 0"
            elsif node.value[1].value[0] == 'odd'
              "(position() mod 2) = 1"
            else
              "(position() mod #{node.value[1].value[0]}) = #{node.value[1].value[3] || 0}"
            end
          else
            "position() = " + node.value[1]
          end
        when /^(first|first-of-type)\(/
          "position() = 1"
        when /^(last|last-of-type)\(/
          "position() = last()"
        when /^nth-last-of-type\(/
          "position() = last() - #{node.value[1]}"
        else
          node.value.first + ')'
        end
      end

      def visit_preceding_selector node
        node.value.last.accept(self) +
          '[preceding-sibling::' +
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
        if node.value.first.is_a?(Nokogiri::CSS::Node) and node.value.first.type == :FUNCTION
          node.value.first.accept(self)
        else
          case node.value.first
          when "first" then "position() = 1"
          when "last" then "position() = last()"
          else
            '1 = 1'
          end
        end
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
