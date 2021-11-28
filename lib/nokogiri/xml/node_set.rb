# frozen_string_literal: true

module Nokogiri
  module XML
    ####
    # A NodeSet contains a list of Nokogiri::XML::Node objects.  Typically
    # a NodeSet is return as a result of searching a Document via
    # Nokogiri::XML::Searchable#css or Nokogiri::XML::Searchable#xpath
    class NodeSet < ::Array
      include Nokogiri::XML::Searchable

      # The Document this NodeSet is associated with
      attr_accessor :document

      # Create a NodeSet with +document+ defaulting to +list+
      # TODO: test that it can only contain Node and Namespace objects
      def initialize(document, list = [])
        super()
        @document = document
        document.decorate(self)
        list.each { |x| self << x }
        yield self if block_given?
      end

      ###
      # Insert +datum+ before the first Node in this NodeSet
      # TODO: this method only makes sense in the context of siblings
      def before(datum)
        first.before(datum)
      end

      ###
      # Insert +datum+ after the last Node in this NodeSet
      # TODO: this method only makes sense in the context of siblings
      def after(datum)
        last.after(datum)
      end

      #  call-seq:
      #    unlink
      #
      # Unlink this NodeSet and all Node objects it contains from their current context.
      def unlink
        reject(&:namespace?).each(&:unlink)
        self
      end
      alias_method :remove, :unlink

      ###
      # call-seq: css *rules, [namespace-bindings, custom-pseudo-class]
      #
      # Search this node set for CSS +rules+. +rules+ must be one or more CSS
      # selectors. For example:
      #
      # For more information see Nokogiri::XML::Searchable#css
      def css(*args)
        rules, handler, ns, _ = extract_params(args)
        paths = css_rules_to_xpath(rules, ns)

        inject(NodeSet.new(document)) do |set, node|
          set + xpath_internal(node, paths, handler, ns, nil)
        end
      end

      ###
      # call-seq: xpath *paths, [namespace-bindings, variable-bindings, custom-handler-class]
      #
      # Search this node set for XPath +paths+. +paths+ must be one or more XPath
      # queries.
      #
      # For more information see Nokogiri::XML::Searchable#xpath
      def xpath(*args)
        paths, handler, ns, binds = extract_params(args)

        inject(NodeSet.new(document)) do |set, node|
          set + xpath_internal(node, paths, handler, ns, binds)
        end
      end

      ###
      # call-seq: search *paths, [namespace-bindings, xpath-variable-bindings, custom-handler-class]
      #
      # Search this object for +paths+, and return only the first
      # result. +paths+ must be one or more XPath or CSS queries.
      #
      # See Searchable#search for more information.
      #
      # Or, if passed an integer, index into the NodeSet:
      #
      #   node_set.at(3) # same as node_set[3]
      #
      def at(*args)
        if args.length == 1 && args.first.is_a?(Numeric)
          return self[args.first]
        end

        super(*args)
      end
      alias_method :%, :at

      ###
      # Filter this list for nodes that match +expr+
      # TODO: make comp with Enumerable#filter
      def filter(expr)
        find_all { |node| node.matches?(expr) }
      end

      ###
      # Add the class attribute +name+ to all Node objects in the
      # NodeSet.
      #
      # See Nokogiri::XML::Node#add_class for more information.
      def add_class(name)
        each do |el|
          el.add_class(name)
        end
        self
      end

      ###
      # Append the class attribute +name+ to all Node objects in the
      # NodeSet.
      #
      # See Nokogiri::XML::Node#append_class for more information.
      def append_class(name)
        each do |el|
          el.append_class(name)
        end
        self
      end

      ###
      # Remove the class attribute +name+ from all Node objects in the
      # NodeSet.
      #
      # See Nokogiri::XML::Node#remove_class for more information.
      def remove_class(name = nil)
        each do |el|
          el.remove_class(name)
        end
        self
      end

      ###
      # Set attributes on each Node in the NodeSet, or get an
      # attribute from the first Node in the NodeSet.
      #
      # To get an attribute from the first Node in a NodeSet:
      #
      #   node_set.attr("href") # => "https://www.nokogiri.org"
      #
      # Note that an empty NodeSet will return nil when +#attr+ is called as a getter.
      #
      # To set an attribute on each node, +key+ can either be an
      # attribute name, or a Hash of attribute names and values. When
      # called as a setter, +#attr+ returns the NodeSet.
      #
      # If +key+ is an attribute name, then either +value+ or +block+
      # must be passed.
      #
      # If +key+ is a Hash then attributes will be set for each
      # key/value pair:
      #
      #   node_set.attr("href" => "https://www.nokogiri.org", "class" => "member")
      #
      # If +value+ is passed, it will be used as the attribute value
      # for all nodes:
      #
      #   node_set.attr("href", "https://www.nokogiri.org")
      #
      # If +block+ is passed, it will be called on each Node object in
      # the NodeSet and the return value used as the attribute value
      # for that node:
      #
      #   node_set.attr("class") { |node| node.name }
      #
      def attr(key, value = nil, &block)
        unless key.is_a?(Hash) || (key && (value || block))
          return first ? first.attribute(key) : nil
        end

        hash = key.is_a?(Hash) ? key : { key => value }

        hash.each do |k, v|
          each do |node|
            node[k] = v || yield(node)
          end
        end

        self
      end
      alias_method :set, :attr
      alias_method :attribute, :attr

      ###
      # Remove the attributed named +name+ from all Node objects in the NodeSet
      def remove_attr(name)
        each { |el| el.delete(name) }
        self
      end
      alias_method :remove_attribute, :remove_attr

      ###
      # Get the inner text of all contained Node objects
      #
      # Note: This joins the text of all Node objects in the NodeSet:
      #
      #    doc = Nokogiri::XML('<xml><a><d>foo</d><d>bar</d></a></xml>')
      #    doc.css('d').text # => "foobar"
      #
      # Instead, if you want to return the text of all nodes in the NodeSet:
      #
      #    doc.css('d').map(&:text) # => ["foo", "bar"]
      #
      # See Nokogiri::XML::Node#content for more information.
      def inner_text
        collect(&:inner_text).join("")
      end
      alias_method :text, :inner_text

      ###
      # Get the inner html of all contained Node objects
      def inner_html(*args)
        collect { |j| j.inner_html(*args) }.join("")
      end

      ###
      # Wrap this NodeSet with +html+
      def wrap(html)
        map { |node| node.wrap(html) }
      end

      ###
      # Convert this NodeSet to a string.
      def to_s
        map(&:to_s).join
      end

      ###
      # Convert this NodeSet to HTML
      def to_html(*args)
        if Nokogiri.jruby?
          options = args.first.is_a?(Hash) ? args.shift : {}
          options[:save_with] ||= Node::SaveOptions::DEFAULT_HTML
          args.insert(0, options)
        end
        map { |x| x.to_html(*args) }.join
      end

      ###
      # Convert this NodeSet to XHTML
      def to_xhtml(*args)
        map { |x| x.to_xhtml(*args) }.join
      end

      ###
      # Convert this NodeSet to XML
      def to_xml(*args)
        map { |x| x.to_xml(*args) }.join
      end

      ###
      # Returns a new NodeSet containing all the children of all the nodes in
      # the NodeSet
      def children
        node_set = NodeSet.new(document)
        each do |node|
          node.children.each { |n| node_set.push(n) }
        end
        node_set
      end

      ###
      # Returns a new NodeSet containing all the nodes in the NodeSet
      # in reverse order
      def reverse
        NodeSet.new(document, super)
      end

      # TODO: document
      def difference(*args)
        NodeSet.new(document, super)
      end
      alias_method :-, :difference

      # TODO: document
      # TODO: can raise TypeError (was formerly ArgumentError)
      def union(other)
        NodeSet.new(document, super)
      end
      alias_method :+, :union
      alias_method :|, :union

      # TODO: document
      def intersection(*args)
        NodeSet.new(document, super)
      end
      alias_method :&, :intersection

      # TODO: document
      def slice(*args)
        result = super
        Array === result ? NodeSet.new(document, result) : result
      end
      alias_method :[], :slice

      # TODO: document
      def dup
        NodeSet.new(document, super)
      end

      IMPLIED_XPATH_CONTEXTS = [".//", "self::"].freeze # :nodoc:
    end
  end
end
