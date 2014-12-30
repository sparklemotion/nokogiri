module Nokogiri
  module XML
    #
    #  The Searchable module declares the interface used for searching your DOM.
    #
    #  It implements the public methods `search`, `css`, and `xpath`,
    #  as well as allowing specific implementations to specialize some
    #  of the important behaviors.
    #
    module Searchable
      # Regular expression used by Node#search to determine if a query
      # string is CSS or XPath
      LOOKS_LIKE_XPATH = /^(\.\/|\/|\.\.|\.$)/
      
      ###
      # call-seq: search *paths, [namespace-bindings, xpath-variable-bindings, custom-handler-class]
      #
      # Search this object for +paths+. +paths+ must be one or more XPath or CSS queries:
      #
      #   node.search("div.employee", ".//title")
      #
      # A hash of namespace bindings may be appended:
      #
      #   node.search('.//bike:tire', {'bike' => 'http://schwinn.com/'})
      #   node.search('bike|tire', {'bike' => 'http://schwinn.com/'})
      #
      # For XPath queries, a hash of variable bindings may also be
      # appended to the namespace bindings. For example:
      #
      #   node.search('.//address[@domestic=$value]', nil, {:value => 'Yes'})
      #
      # Custom XPath functions and CSS pseudo-selectors may also be
      # defined. To define custom functions create a class and
      # implement the function you want to define.  The first argument
      # to the method will be the current matching NodeSet.  Any other
      # arguments are ones that you pass in.  Note that this class may
      # appear anywhere in the argument list.  For example:
      #
      #   node.search('.//title[regex(., "\w+")]', 'div.employee:regex("[0-9]+")'
      #     Class.new {
      #       def regex node_set, regex
      #         node_set.find_all { |node| node['some_attribute'] =~ /#{regex}/ }
      #       end
      #     }.new
      #   )
      #
      # See Searchable#xpath and Searchable#css for further usage help.
      def search *args
        paths, handler, ns, binds = extract_params(args)

        xpaths = paths.map do |path|
          path = path.to_s
          if path =~ LOOKS_LIKE_XPATH
            path
          else
            implied_xpath_contexts.map do |implied_xpath_context|
              CSS.xpath_for(path, :prefix => implied_xpath_context, :ns => ns)
            end.join(' | ')
          end
        end.flatten.uniq

        xpath(*(xpaths + [ns, handler, binds].compact))
      end
      alias :/ :search

      ###
      # call-seq: css *rules, [namespace-bindings, custom-pseudo-class]
      #
      # Search this object for CSS +rules+. +rules+ must be one or more CSS
      # selectors. For example:
      #
      #   node.css('title')
      #   node.css('body h1.bold')
      #   node.css('div + p.green', 'div#one')
      #
      # A hash of namespace bindings may be appended. For example:
      #
      #   node.css('bike|tire', {'bike' => 'http://schwinn.com/'})
      #
      # Custom CSS pseudo classes may also be defined.  To define
      # custom pseudo classes, create a class and implement the custom
      # pseudo class you want defined.  The first argument to the
      # method will be the current matching NodeSet.  Any other
      # arguments are ones that you pass in.  For example:
      #
      #   node.css('title:regex("\w+")', Class.new {
      #     def regex node_set, regex
      #       node_set.find_all { |node| node['some_attribute'] =~ /#{regex}/ }
      #     end
      #   }.new)
      #
      # Note that the CSS query string is case-sensitive with regards
      # to your document type. That is, if you're looking for "H1" in
      # an HTML document, you'll never find anything, since HTML tags
      # will match only lowercase CSS queries. However, "H1" might be
      # found in an XML document, where tags names are case-sensitive
      # (e.g., "H1" is distinct from "h1").
      #
      def css *args
        rules, handler, ns, binds = extract_params(args)

        css_internal self, rules, handler, ns
      end

      # TODO: :at, :%, :at_css, :at_xpath

      private

      def css_internal node, rules, handler, ns
        xpaths = rules.map { |rule| xpath_query_from_css_rule(rule, ns) }
        node.xpath(*(xpaths + [ns, handler].compact))
      end

      def xpath_query_from_css_rule rule, ns
        implied_xpath_contexts.map do |implied_xpath_context|
          CSS.xpath_for(rule.to_s, :prefix => implied_xpath_context, :ns => ns)
        end.join(' | ')
      end

      def extract_params params # :nodoc:
        handler = params.find do |param|
          ![Hash, String, Symbol].include?(param.class)
        end
        params -= [handler] if handler

        hashes = []
        while Hash === params.last || params.last.nil?
          hashes << params.pop
          break if params.empty?
        end
        ns, binds = hashes.reverse

        ns ||= document.root ? document.root.namespaces : {}

        [params, handler, ns, binds]
      end
    end
  end
end
