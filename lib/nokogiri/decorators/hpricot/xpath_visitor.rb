module Nokogiri
  module Decorators
    module Hpricot
      ####
      # This mixin does custom adjustments to deal with _whyML
      module XPathVisitor
        def visit_attribute_condition node
          super(node).gsub(/child::text\(\)/, 'normalize-space(child::text())')
        end
      end
    end
  end
end
