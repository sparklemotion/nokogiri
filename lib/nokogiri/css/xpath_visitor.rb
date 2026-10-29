# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  module CSS
    # When translating CSS selectors to XPath queries with Nokogiri::CSS.xpath_for, the XPathVisitor
    # class allows for changing some of the behaviors related to builtin xpath functions and quirks
    # of HTML5.
    class XPathVisitor
      WILDCARD_NAMESPACES = Nokogiri.libxml2_patches.include?("0009-allow-wildcard-namespaces.patch") # :nodoc:

      # The ASCII characters allowed in an XML NCName. Every XPath delimiter and operator is ASCII,
      # so non-ASCII characters are left for the XPath parser to accept or reject.
      XPATH_NAME = /\A(?:[A-Za-z_]|[^\x00-\x7F])(?:[A-Za-z0-9_.-]|[^\x00-\x7F])*\z/
      private_constant :XPATH_NAME

      # Enum to direct XPathVisitor when to use Nokogiri builtin XPath functions.
      module BuiltinsConfig
        # Never use Nokogiri builtin functions, always generate vanilla XPath 1.0 queries. This is
        # the default when calling Nokogiri::CSS.xpath_for directly.
        NEVER = :never

        # Always use Nokogiri builtin functions whenever possible. This is probably only useful for testing.
        ALWAYS = :always

        # Only use Nokogiri builtin functions when they will be faster than vanilla XPath. This is
        # the behavior chosen when searching for CSS selectors on a Nokogiri document, fragment, or
        # node.
        OPTIMAL = :optimal

        # :nodoc: array of values for validation
        VALUES = [NEVER, ALWAYS, OPTIMAL]
      end

      # Enum to direct XPathVisitor when to tweak the XPath query to suit the nature of the document
      # being searched. Note that searches for CSS selectors from a Nokogiri document, fragment, or
      # node will choose the correct option automatically.
      module DoctypeConfig
        # The document being searched is an XML document. This is the default.
        XML = :xml

        # The document being searched is an HTML4 document.
        HTML4 = :html4

        # The document being searched is an HTML5 document.
        HTML5 = :html5

        # :nodoc: array of values for validation
        VALUES = [XML, HTML4, HTML5]
      end

      # The visitor configuration set via the +builtins:+ keyword argument to XPathVisitor.new.
      attr_reader :builtins

      # The visitor configuration set via the +doctype:+ keyword argument to XPathVisitor.new.
      attr_reader :doctype

      # The visitor configuration set via the +prefix:+ keyword argument to XPathVisitor.new.
      attr_reader :prefix

      # The visitor configuration set via the +namespaces:+ keyword argument to XPathVisitor.new.
      attr_reader :namespaces

      # :call-seq:
      #   new() → XPathVisitor
      #   new(builtins:, doctype:) → XPathVisitor
      #
      # [Parameters]
      # - +builtins:+ (BuiltinsConfig) Determine when to use Nokogiri's built-in xpath functions for performance improvements.
      # - +doctype:+ (DoctypeConfig) Make document-type-specific accommodations for CSS queries.
      #
      # [Returns] XPathVisitor
      #
      def initialize(
        builtins: BuiltinsConfig::NEVER,
        doctype: DoctypeConfig::XML,
        prefix: Nokogiri::XML::XPath::GLOBAL_SEARCH_PREFIX,
        namespaces: nil
      )
        unless BuiltinsConfig::VALUES.include?(builtins)
          raise(ArgumentError, "Invalid values #{builtins.inspect} for builtins: keyword parameter")
        end
        unless DoctypeConfig::VALUES.include?(doctype)
          raise(ArgumentError, "Invalid values #{doctype.inspect} for doctype: keyword parameter")
        end

        @builtins = builtins
        @doctype = doctype
        @prefix = prefix
        @namespaces = namespaces
      end

      # :call-seq: config() → Hash
      #
      # [Returns]
      #   a Hash representing the configuration of the XPathVisitor, suitable for use as
      #   part of the CSS cache key.
      def config
        { builtins: @builtins, doctype: @doctype, prefix: @prefix, namespaces: @namespaces }
      end

      # :stopdoc:
      def visit_function(node)
        msg = :"visit_function_#{node.value.first.gsub(/[(]/, "")}"
        return send(msg, node) if respond_to?(msg)

        case node.value.first
        when /^text\(/
          "child::text()"
        when /^self\(/
          "self::#{node.value[1]}"
        when /^eq\(/
          "position()=#{node.value[1]}"
        when /^(nth|nth-of-type)\(/
          if node.value[1].is_a?(Nokogiri::CSS::Node) && (node.value[1].type == :NTH)
            nth(node.value[1])
          else
            "position()=#{node.value[1]}"
          end
        when /^nth-child\(/
          if node.value[1].is_a?(Nokogiri::CSS::Node) && (node.value[1].type == :NTH)
            nth(node.value[1], child: true)
          else
            "count(preceding-sibling::*)=#{node.value[1].to_i - 1}"
          end
        when /^nth-last-of-type\(/
          if node.value[1].is_a?(Nokogiri::CSS::Node) && (node.value[1].type == :NTH)
            nth(node.value[1], last: true)
          else
            index = node.value[1].to_i - 1
            index == 0 ? "position()=last()" : "position()=last()-#{index}"
          end
        when /^nth-last-child\(/
          if node.value[1].is_a?(Nokogiri::CSS::Node) && (node.value[1].type == :NTH)
            nth(node.value[1], last: true, child: true)
          else
            "count(following-sibling::*)=#{node.value[1].to_i - 1}"
          end
        when /^(first|first-of-type)\(/
          "position()=1"
        when /^(last|last-of-type)\(/
          "position()=last()"
        when /^contains\(/
          "contains(.,#{xpath_function_argument(node.value[1])})"
        when /^gt\(/
          "position()>#{node.value[1]}"
        when /^only-child\(/
          "last()=1"
        when /^comment\(/
          "comment()"
        when /^has\(/
          is_direct = node.value[1].value[0].nil? # e.g. "has(> a)", "has(~ a)", "has(+ a)"
          ".#{"//" unless is_direct}#{node.value[1].accept(self)}"
        else
          validate_xpath_function_name(node.value.first)

          # xpath function call, let's marshal those arguments
          args = ["."]
          args += node.value[1..-1].map { |arg| xpath_function_argument(arg) }
          "nokogiri:#{node.value.first}#{args.join(",")})"
        end
      end

      def visit_not(node)
        child = node.value.first
        if :ELEMENT_NAME == child.type
          "not(self::#{child.accept(self)})"
        else
          "not(#{child.accept(self)})"
        end
      end

      def visit_id(node)
        "@id=#{xpath_string_literal(node.value.first.delete_prefix("#"))}"
      end

      def visit_attribute_condition(node)
        attribute = node.value.first.accept(self)
        return attribute if node.value.length == 1

        str_value = node.value.last
        value = xpath_string_literal(str_value)

        case node.value[1]
        when :equal
          attribute + "=" + value.to_s
        when :not_equal
          attribute + "!=" + value.to_s
        when :substring_match
          "contains(#{attribute},#{value})"
        when :prefix_match
          "starts-with(#{attribute},#{value})"
        when :dash_match
          "#{attribute}=#{value} or starts-with(#{attribute},concat(#{value},'-'))"
        when :includes
          css_class(attribute, str_value)
        when :suffix_match
          "substring(#{attribute},string-length(#{attribute})-string-length(#{value})+1,string-length(#{value}))=#{value}"
        else
          attribute + " #{node.value[1]} " + value.to_s
        end
      end

      def visit_pseudo_class(node)
        if node.value.first.is_a?(Nokogiri::CSS::Node) && (node.value.first.type == :FUNCTION)
          node.value.first.accept(self)
        else
          msg = :"visit_pseudo_class_#{node.value.first.gsub(/[(]/, "")}"
          return send(msg, node) if respond_to?(msg)

          case node.value.first
          when "first" then "position()=1"
          when "first-child" then "count(preceding-sibling::*)=0"
          when "last" then "position()=last()"
          when "last-child" then "count(following-sibling::*)=0"
          when "first-of-type" then "position()=1"
          when "last-of-type" then "position()=last()"
          when "only-child" then "count(preceding-sibling::*)=0 and count(following-sibling::*)=0"
          when "only-of-type" then "last()=1"
          when "empty" then "not(node())"
          when "parent" then "node()"
          when "root" then "not(parent::*)"
          else
            validate_xpath_function_name(node.value.first)
            "nokogiri:#{node.value.first}(.)"
          end
        end
      end

      def visit_class_condition(node)
        css_class("@class", node.value.first)
      end

      def visit_combinator(node)
        if is_of_type_pseudo_class?(node.value.last)
          "#{node.value.first&.accept(self)}][#{node.value.last.accept(self)}"
        else
          "#{node.value.first&.accept(self)} and #{node.value.last.accept(self)}"
        end
      end

      {
        "direct_adjacent_selector" => "/following-sibling::*[1]/self::",
        "following_selector" => "/following-sibling::",
        "descendant_selector" => "//",
        "child_selector" => "/",
      }.each do |k, v|
        class_eval <<~RUBY, __FILE__, __LINE__ + 1
          def visit_#{k} node
            "\#{node.value.first.accept(self) if node.value.first}#{v}\#{node.value.last.accept(self)}"
          end
        RUBY
      end

      def visit_conditional_selector(node)
        node.value.first.accept(self) + "[" +
          node.value.last.accept(self) + "]"
      end

      def visit_element_name(node)
        html5_local_name = @doctype == DoctypeConfig::HTML5 && html5_element_name_needs_namespace_handling(node)
        node.value.each { |name| validate_xpath_element_name(name) } unless html5_local_name

        if html5_local_name
          # HTML5 has namespaces that should be ignored in CSS queries
          # https://github.com/sparklemotion/nokogiri/issues/2376
          name = node.value.first
          if @builtins == BuiltinsConfig::ALWAYS || (@builtins == BuiltinsConfig::OPTIMAL && Nokogiri.uses_libxml?)
            if WILDCARD_NAMESPACES && xpath_name?(name)
              "*:#{name}"
            else
              "*[nokogiri-builtin:local-name-is(#{xpath_string_literal(name)})]"
            end
          else
            "*[local-name()=#{xpath_string_literal(name)}]"
          end
        elsif node.value.length == 2 # has a namespace prefix
          if node.value.first.nil? # namespace prefix is empty
            node.value.last
          else
            node.value.join(":")
          end
        elsif node.value.first != "*" && @namespaces&.key?("xmlns")
          # apply the default namespace (if one is present) to a non-wildcard selector
          "xmlns:#{node.value.first}"
        else
          node.value.first
        end
      end

      def visit_attrib_name(node)
        if node.value.length == 2 # has a namespace prefix
          unless node.value.all? { |name| xpath_name?(name) }
            raise Nokogiri::CSS::SyntaxError, "Invalid attribute name '#{node.value.join("|")}'"
          end

          "@#{node.value.join(":")}"
        elsif xpath_name?(node.value.first)
          "@#{node.value.first}"
        else
          # HTML parsers allow attribute names like "@click" and ":class". On JRuby, local-name() of ":class" is "class".
          "@*[namespace-uri()='' and name()=#{xpath_string_literal(node.value.first)}]"
        end
      end

      def accept(node)
        node.accept(self)
      end

      private

      def validate_xpath_function_name(name)
        if name.start_with?("-")
          raise Nokogiri::CSS::SyntaxError, "Invalid XPath function name '#{name}'"
        end
      end

      def validate_xpath_element_name(name)
        unless name.nil? || name == "*" || xpath_name?(name)
          raise Nokogiri::CSS::SyntaxError, "Invalid element name '#{name}'"
        end
      end

      def xpath_name?(name)
        XPATH_NAME.match?(name)
      end

      # Function arguments reach the visitor as raw tokens, and only a STRING token starts with a quote.
      def xpath_function_argument(arg)
        if arg.is_a?(Nokogiri::CSS::Node)
          arg.accept(self)
        elsif arg.is_a?(String) && arg.start_with?("'", '"')
          xpath_string_literal(Parser.unescape_css_string(arg[1..-2]))
        else
          arg
        end
      end

      def html5_element_name_needs_namespace_handling(node)
        # if there is already a namespace (i.e., it is a prefixed QName), use it as normal
        node.value.length == 1 &&
          # if this is the wildcard selector "*", use it as normal
          node.value.first != "*"
      end

      def nth(node, options = {})
        unless node.value.size == 4
          raise(ArgumentError, "expected an+b node to contain 4 tokens, but is #{node.value.inspect}")
        end

        a, b = read_a_and_positive_b(node.value)
        position = if options[:child]
          options[:last] ? "(count(following-sibling::*)+1)" : "(count(preceding-sibling::*)+1)"
        else
          options[:last] ? "(last()-position()+1)" : "position()"
        end

        if a.zero?
          "#{position}=#{b}"
        elsif b.zero? && a.positive?
          "(#{position} mod #{a})=0"
        else
          compare = a < 0 ? "<=" : ">="
          if a.abs == 1
            "#{position}#{compare}#{b}"
          else
            "(#{position}#{compare}#{b}) and (((#{position}-#{b}) mod #{a.abs})=0)"
          end
        end
      end

      def read_a_and_positive_b(values)
        op = values[2].strip
        if op == "+"
          a = values[0].to_i
          b = values[3].to_i
        elsif op == "-"
          a = values[0].to_i
          b = a.zero? ? -values[3].to_i : a - (values[3].to_i % a)
        else
          raise ArgumentError, "expected an+b node to have either + or - as the operator, but is #{op.inspect}"
        end
        [a, b]
      end

      def is_of_type_pseudo_class?(node)
        if node.type == :PSEUDO_CLASS
          if node.value[0].is_a?(Nokogiri::CSS::Node) && (node.value[0].type == :FUNCTION)
            node.value[0].value[0]
          else
            node.value[0]
          end =~ /(nth|first|last|only)-of-type(\()?/
        end
      end

      def css_class(hay, needle)
        if @builtins == BuiltinsConfig::ALWAYS || (@builtins == BuiltinsConfig::OPTIMAL && Nokogiri.uses_libxml?)
          # use the builtin implementation
          "nokogiri-builtin:css-class(#{hay},#{xpath_string_literal(needle)})"
        else
          # use only ordinary xpath functions
          "contains(concat(' ',normalize-space(#{hay}),' '),#{xpath_string_literal(" #{needle} ")})"
        end
      end

      # XPath 1.0 string literals have no escape mechanism, so a string containing both quote
      # characters has to be assembled with concat().
      def xpath_string_literal(string)
        if !string.include?("'")
          "'#{string}'"
        elsif !string.include?('"')
          %("#{string}")
        else
          "concat('" + string.split("'", -1).join(%q{',"'",'}) + "')"
        end
      end
    end
  end
end
