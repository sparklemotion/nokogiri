module Nokogiri
  module Decorators
    module Hpricot
      module NodeSet
        def filter rule
          ctx = CSS::Parser.parse(rule.to_s)
          visitor = CSS::XPathVisitor.new
          visitor.extend(Hpricot::XPathVisitor)
          search('.//self::' + visitor.accept(ctx.first))
        end
      end
    end
  end
end
