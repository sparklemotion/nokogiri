module Nokogiri
  module Decorators
    module Hpricot
      module Node
        def search path
          super(convert_to_xpath(path))
        end
        def /(path); search(path) end

        def at path
          search("#{path}").first
        end

        def raw_attributes; self end

        def get_element_by_id element_id
          search("//*[@id='#{element_id}']").first
        end

        def get_elements_by_tag_name tag
          search("//#{tag}")
        end

        def convert_to_xpath(rule)
          rule = rule.to_s
          case rule
          when %r{^//}
            ".#{rule}"
          when %r{^/}
            rule
          when %r{^[^\/].*[\/]}
            ".//#{rule}"
          when %r{^.//}
            rule
          else
            ctx = CSS::Parser.parse(rule)
            visitor = CSS::XPathVisitor.new
            visitor.extend(Hpricot::XPathVisitor)
            './/' + visitor.accept(ctx)
          end
        end
      end
    end
  end
end
