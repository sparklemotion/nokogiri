module Nokogiri
  module Decorators
    module Hpricot
      ####
      # This mixin does custom adjustments to deal with _whyML
      module XPathVisitor
        ###
        # Visit attribute condition nodes with +node+
        def visit_attribute_condition node
          unless (node.value.first.type == :FUNCTION) or (node.value.first.value.first =~ /^@/)
            node.value.first.value[0] = "child::" +
              node.value.first.value[0]
          end
          super(node).gsub(/child::text\(\)/, 'normalize-space(child::text())')
        end

        #  take a path like '//t:sam' and convert to xpath "*[name()='t:sam']"
        def self.xpath_namespace_helper rule
          rule.split(/\//).collect do |tag|
            if match = tag.match(/^(\w+:\w+)(.*)/)
              "*[name()='#{match[1]}']#{match[2]}"
            else
              tag
            end
          end.join("/")
        end
      end
    end
  end
end
