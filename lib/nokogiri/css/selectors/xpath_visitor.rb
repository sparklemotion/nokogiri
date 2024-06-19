# frozen_string_literal: true

require_relative "../xpath_visitor"

module Nokogiri
  module CSS
    # :nodoc: all
    class Selectors
      class XPathVisitor < Nokogiri::CSS::XPathVisitorBase
        EMPTY_STRING = ""

        # Generate the XPath expression for the given CSS selector AST.
        def xpath(ast)
          # prefix = if ALLOW_COMBINATOR_ON_SELF.include?(type) && value.first.nil?
          #   "."
          # else
          #   visitor.prefix
          # end
          prefix = if RelativeSelector === ast
            "."
          else
            self.prefix
          end
          prefix + accept(ast)
        end

        # ----------
        # Visitor methods
        # ----------

        def visit_complex_selector(node)
          "#{accept(node.left)}#{accept(node.combinator)}#{accept(node.right)}"
        end

        def visit_relative_selector(node)
          "#{accept(node.combinator)}#{accept(node.complex_selector)}"
        end

        def visit_compound_selector(node)
          type_selector = node.type.nil? ? "*" : accept(node.type)

          subclasses_selector = if node.subclasses.nil? || node.subclasses.empty?
            EMPTY_STRING
          else
            filters = ["["]
            node.subclasses.each_with_index do |subclass, j|
              filters << " and " if j > 0
              filters << accept(subclass)
            end
            filters << "]"
            filters.join
          end

          type_selector + subclasses_selector
        end

        def visit_wq_name(node)
          if node.prefix
            "#{accept(node.prefix)}#{accept(node.name)}"
          else
            accept(node.name)
          end
        end

        def visit_type_selector(node)
          node_name = accept(node.name)
          if @doctype == DoctypeConfig::HTML5 && html5_element_name_needs_namespace_handling(node)
            # HTML5 has namespaces that should be ignored in CSS queries
            # https://github.com/sparklemotion/nokogiri/issues/2376
            if @builtins == BuiltinsConfig::ALWAYS || (@builtins == BuiltinsConfig::OPTIMAL && Nokogiri.uses_libxml?)
              if WILDCARD_NAMESPACES
                "*:#{node_name}"
              else
                "*[nokogiri-builtin:local-name-is(#{quote(node_name)})]"
              end
            else
              "*[local-name()=#{quote(node_name)}]"
            end
          elsif node.prefix
            "#{accept(node.prefix)}#{node_name}"
          elsif @namespaces&.key?("xmlns") # apply the default namespace if it's declared
            "xmlns:#{node_name}"
          else
            node_name
          end
        end

        def visit_ident_token(node)
          node.value
        end

        def visit_combinator_child(node)
          "/"
        end

        def visit_combinator_descendant(node)
          "//"
        end

        def visit_at_keyword_token(node)
          "@#{node.value}"
        end

        def visit_ns_prefix(node)
          node.value.nil? ? EMPTY_STRING : "#{accept(node.value)}:"
        end

        def visit_xpath_function(node)
          f = node.value
          case f.name
          when "text"
            "child::text()"
          when "comment"
            "comment()"
          when "self"
            "self::#{accept(f.value.first)}"
          else
            raise Nokogiri::CSS::SyntaxError, "Unsupported XPath function #{f.inspect}"
          end
        end

        def visit_pseudo_class_function(node)
          # TODO: come back to this when we're the primary execution path
          # msg = :"visit_function_#{node.name}"
          # return send(msg, node) if respond_to?(msg)

          case node.name
          # when "eq"
          #   # TODO
          when "nth", "nth-of-type"
            unless node.arguments.size == 1 && ANPlusB === node.arguments.first
              raise Nokogiri::CSS::SyntaxError, "Unexpected arguments to #{node.name}()"
            end

            "position()=99" # TODO: OBVIOUSLY WRONG
          # when "nth-child"
          #   # TODO
          # when "nth-last-of-type"
          #   # TODO
          # when "nth-last-child"
          #   # TODO
          # when "first", "first-of-type"
          #   # TODO
          # when "last", "last-of-type"
          #   # TODO
          when "contains"
            unless node.arguments.size == 1
              raise Nokogiri::CSS::SyntaxError, "Unexpected arguments to contains()"
            end

            "contains(.,#{quote_accept(node.arguments.first)})"
          when "gt"
            unless node.arguments.size == 1 && ANPlusB === node.arguments.first
              raise Nokogiri::CSS::SyntaxError, "Unexpected arguments to gt(): #{node.arguments}"
            end

            "position()>3" # TODO: OBVIOUSLY WRONG
          # when "only-child"
          #   # TODO
          when "has"
            case node.arguments.first
            when RelativeSelector
              ".#{accept(node.arguments.first)}"
            else
              ".//#{accept(node.arguments.first)}"
            end
          else # custom xpath function call
            # TODO
            "<pseudo-class-function>"
          end
        end

        def visit_pseudo_class_selector(node)
          if PseudoClassFunction === node.value
            return accept(node.value)
          end

          # TODO: come back to this when we're the primary execution path
          # msg = :"visit_pseudo_class_#{node.name}"
          # return send(msg, node) if respond_to?(msg)

          case (node_name = accept(node.value))
          when "shit"
            "shit"
          else
            # TODO: validate_xpath_function_name(node.value.first)
            "nokogiri:#{node_name}(.)"
          end
        end

        def visit_class_selector(node)
          keyword_attribute("@class", node.value)
        end

        def visit_id_selector(node)
          "@id=#{quote_accept(node.value)}"
        end

        def visit_hash_token(node)
          node.value
        end

        def visit_string_token(node)
          quote(node.value)
        end

        def visit_attribute_selector(node)
          case node.matcher
          when nil
            "@#{accept(node.name)}"
          when XPathFunction
            accept(node.matcher)
          when AttributeSelectorMatcher
            case node.matcher.matcher
            when AttrMatcher::IncludeWord
              keyword_attribute(wq_namish(node.name), node.matcher.value)
            when AttrMatcher::Equal
              "#{wq_namish(node.name)}=#{quote_accept(node.matcher.value)}"
            when AttrMatcher::NotEqual
              "#{wq_namish(node.name)}!=#{quote_accept(node.matcher.value)}"
            when AttrMatcher::DashMatch
              name = wq_namish(node.name)
              value = quote_accept(node.matcher.value)
              "#{name}=#{value} or starts-with(#{name},concat(#{value},'-'))"
            when AttrMatcher::StartWith
              "starts-with(#{wq_namish(node.name)},#{quote_accept(node.matcher.value)})"
            when AttrMatcher::EndWith
              name = wq_namish(node.name)
              value = quote_accept(node.matcher.value)
              "substring(#{name},string-length(#{name})-string-length(#{value})+1,string-length(#{value}))=#{value}"
            when AttrMatcher::Include
              "contains(#{wq_namish(node.name)},#{quote_accept(node.matcher.value)})"
            else
              "x" # TODO: OBVIOUSLY REMOVE ME
            end
          else
            raise Nokogiri::CSS::SyntaxError, "Unexpected matcher #{node.matcher}"
          end
        end

        def visit_delim_token(node)
          node.value
        end

        def visit_number_token(node)
          node.value
        end

        private

        # ----------
        # Helpers
        # ----------

        def quote_accept(node)
          case node
          when StringToken
            accept(node)
          else
            quote(accept(node))
          end
        end

        def unquote_accept(node)
          case node
          when StringToken
            node.value
          else
            accept(node)
          end
        end

        def quote(string)
          string = string.to_s
          if string.include?(%('))
            string = string.gsub('"', "&quot;") if string.include?(%("))
            %("#{string}")
          else
            %('#{string}')
          end
        end

        # we accept "@name" in a lot of places as extended syntax where normally CSS only expects wq-names.
        def wq_namish(node)
          case node
          when AtKeywordToken
            accept(node)
          else
            "@#{accept(node)}"
          end
        end

        # if there is already a namespace (i.e., it is a prefixed QName), use it as normal
        # if this is the wildcard selector "*", use it as normal
        def html5_element_name_needs_namespace_handling(node)
          node.prefix.nil? && node.name != "*"
        end

        def keyword_attribute(hay, needle)
          if @builtins == BuiltinsConfig::ALWAYS || (@builtins == BuiltinsConfig::OPTIMAL && Nokogiri.uses_libxml?)
            # use the builtin implementation
            "nokogiri-builtin:css-class(#{hay},#{quote_accept(needle)})"
          else
            # use only ordinary xpath functions
            needle_name = " #{unquote_accept(needle)} " # pad with spaces
            "contains(concat(' ',normalize-space(#{hay}),' '),#{quote(needle_name)})"
          end
        end
      end
    end
  end
end
