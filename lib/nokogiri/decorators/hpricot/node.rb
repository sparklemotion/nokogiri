module Nokogiri
  module Decorators
    module Hpricot
      module Node
        def search *paths
          ns = paths.last.is_a?(Hash) ? paths.pop : {}
          converted = paths.map { |path|
            convert_to_xpath(path)
          }.flatten.uniq

          namespaces = document.xml? ? document.namespaces.merge(ns) : ns
          super(*converted + [namespaces])
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
            [".#{rule}"]
          when %r{^/}
            [rule]
          when %r{^.//}
            [rule]
          else
            ctx = CSS::Parser.parse(rule)
            visitor = CSS::XPathVisitor.new
            visitor.extend(Hpricot::XPathVisitor)
            ctx.map { |ast| './/' + visitor.accept(ast.preprocess!) }
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
