module Nokogiri
  module Decorators
    module Hpricot
      ####
      # This mixin does custom adjustments to deal with _whyML
      module XPathVisitor
        def visit_attribute_condition node
          unless (node.value.first.type == :FUNCTION) or (node.value.first.value.first =~ /^@/)
            node.value.first.value[0] = "child::" +
              node.value.first.value[0]
          end
          super(node).gsub(/child::text\(\)/, 'normalize-space(child::text())')
        end
      end
    end
  end
end
