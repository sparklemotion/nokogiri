module Nokogiri
  module Decorators
    module Hpricot
      module Node # :nodoc:
        def search *paths
          ns = paths.last.is_a?(Hash) ? paths.pop : {}
          converted = paths.map { |path|
            convert_to_xpath(path)
          }.flatten.uniq

          super(*converted + [ns])
        end
        def /(path); search(path) end

        def xpath *args
          return super if args.length > 0
          path
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
            [".#{Hpricot::XPathVisitor.xpath_namespace_helper(rule)}"]
          when %r{^/}
            [Hpricot::XPathVisitor.xpath_namespace_helper(rule)]
          when %r{^.//}
            [Hpricot::XPathVisitor.xpath_namespace_helper(rule)]
          else
            visitor = CSS::XPathVisitor.new
            visitor.extend(Hpricot::XPathVisitor)
            CSS.xpath_for(rule, :prefix => ".//", :visitor => visitor)
          end
        end

        def target
          name
        end

        def to_original_html
          to_html
        end
      end
    end
  end
end
