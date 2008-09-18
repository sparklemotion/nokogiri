module Nokogiri
  module Decorators
    module Hpricot
      ####
      # This mixin does custom adjustments to deal with _whyML
      module XPathVisitor
        def visit_function node
          return 'normalize-space(child::text())' if node.value.first == 'text('
          super
        end
      end
    end
  end
end
