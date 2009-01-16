module Nokogiri
  module XML
    class Node
      ELEMENT_NODE =       1
      ATTRIBUTE_NODE =     2
      TEXT_NODE =          3
      CDATA_SECTION_NODE = 4
      ENTITY_REF_NODE =    5
      ENTITY_NODE =        6
      PI_NODE =            7
      COMMENT_NODE =       8
      DOCUMENT_NODE =      9
      DOCUMENT_TYPE_NODE = 10
      DOCUMENT_FRAG_NODE = 11
      NOTATION_NODE =      12
      HTML_DOCUMENT_NODE = 13
      DTD_NODE =           14
      ELEMENT_DECL =       15
      ATTRIBUTE_DECL =     16
      ENTITY_DECL =        17
      NAMESPACE_DECL =     18
      XINCLUDE_START =     19
      XINCLUDE_END =       20
      DOCB_DOCUMENT_NODE = 21

      attr_accessor :document

      ###
      # Decorate this node with the decorators set up in this node's Document
      def decorate!
        document.decorate(self) if document
      end

      ###
      # Get the list of children for this node as a NodeSet
      def children
        list = NodeSet.new(document)
        document.decorate(list)

        first = self.child
        return list unless first # Empty list

        list << first
        while first = first.next
          list << first
        end
        list
      end

      ###
      # Search this node for +paths+.  +paths+ can be XPath or CSS, and an
      # optional hash of namespaces may be appended.
      # See Node#xpath and Node#css.
      def search *paths
        ns = paths.last.is_a?(Hash) ? paths.pop : {}
        xpath(*(paths.map { |path|
          path = path.to_s
          path =~ /^(\.\/|\/)/ ? path : CSS.xpath_for(path, :prefix => ".//")
        }.flatten.uniq) + [ns])
      end
      alias :/ :search

      ###
      # Search this node for XPath +paths+. +paths+ must be one or more XPath
      # queries.  A hash of namespaces may be appended.  For example:
      #
      #   node.xpath('.//title')
      #   node.xpath('.//foo:name', { 'foo' => 'http://example.org/' })
      #   node.xpath('.//xmlns:name', node.root.namespaces)
      #
      # Custom XPath functions may also be defined.  To define custom functions
      # create a class and implement the # function you want to define.
      # For example:
      #
      #   node.xpath('.//title[regex(., "\w+")]', Class.new {
      #     def regex node_set, regex
      #       node_set.find_all { |node| node['some_attribute'] =~ /#{regex}/ }
      #     end
      #   })
      #
      def xpath *paths
        # Pop off our custom function handler if it exists
        handler = ![
          Hash, String, Symbol
        ].include?(paths.last.class) ? paths.pop : nil

        ns = paths.last.is_a?(Hash) ? paths.pop : {}

        return NodeSet.new(document) unless document.root

        sets = paths.map { |path|
          ctx = XPathContext.new(self)
          ctx.register_namespaces(ns)
          set = ctx.evaluate(path, handler).node_set
          set.document = document
          document.decorate(set)
          set
        }
        return sets.first if sets.length == 1

        NodeSet.new(document) do |combined|
          document.decorate(combined)
          sets.each do |set|
            set.each do |node|
              combined << node
            end
          end
        end
      end

      ###
      # Search this node for CSS +rules+. +rules+ must be one or more CSS
      # selectors.  For example:
      #
      #   node.css('title')
      #   node.css('body h1.bold')
      #   node.css('div + p.green', 'div#one')
      #
      # Custom CSS pseudo classes may also be defined.  To define custom pseudo
      # classes, create a class and implement the custom pseudo class you
      # want defined.  The first argument to the method will be the current
      # matching NodeSet.  Any other arguments are ones that you pass in.
      # For example:
      #
      #   node.css('title:regex("\w+")', Class.new {
      #     def regex node_set, regex
      #       node_set.find_all { |node| node['some_attribute'] =~ /#{regex}/ }
      #     end
      #   })
      #
      def css *rules
        # Pop off our custom function handler if it exists
        handler = ![
          Hash, String, Symbol
        ].include?(rules.last.class) ? rules.pop : nil

        ns = rules.last.is_a?(Hash) ? rules.pop : {}

        rules = rules.map { |rule|
          CSS.xpath_for(rule, :prefix => ".//")
        }.flatten.uniq + [ns, handler].compact

        xpath(*rules)
      end

      def at path, ns = {}
        search(path, ns).first
      end

      def [](property)
        return nil unless key?(property)
        get(property)
      end

      def next
        next_sibling
      end

      def previous
        previous_sibling
      end

      def remove
        unlink
      end

      ####
      # Returns a hash containing the node's attributes.  The key is the
      # attribute name, the value is the string value of the attribute.
      def attributes
        Hash[*(attribute_nodes.map { |node|
          [node.name, node]
        }.flatten)]
      end

      ###
      # Remove the attribute named +name+
      def remove_attribute name
        attributes[name].remove if key? name
      end
      alias :delete :remove_attribute

      ####
      # Create nodes from +data+ and insert them before this node
      # (as a sibling).
      def before data
        classes = document.class.name.split('::')
        classes[-1] = 'SAX::Parser'

        parser = eval(classes.join('::')).new(BeforeHandler.new(self, data))
        parser.parse(data)
      end

      ####
      # Create nodes from +data+ and insert them after this node
      # (as a sibling).
      def after data
        classes = document.class.name.split('::')
        classes[-1] = 'SAX::Parser'

        handler = AfterHandler.new(self, data)
        parser = eval(classes.join('::')).new(handler)
        parser.parse(data)
        handler.after_nodes.reverse.each do |sibling|
          self.add_next_sibling sibling
        end
      end

      def has_attribute?(property)
        key? property
      end

      alias :get_attribute :[]
      def set_attribute(name, value)
        self[name] = value
      end

      def text
        content
      end
      alias :inner_text :text

      ####
      # Set the content to +string+.
      # If +encode+, encode any special characters first.
      def content= string, encode = true
        self.native_content = encode_special_chars(string)
      end

      ###
      # Set the parent Node for this Node
      def parent= parent_node
        parent_node.add_child(self)
        parent_node
      end

      def << child
        add_child child
      end

      def comment?
        type == COMMENT_NODE
      end

      def cdata?
        type == CDATA_SECTION_NODE
      end

      def xml?
        type == DOCUMENT_NODE
      end

      def html?
        type == HTML_DOCUMENT_NODE
      end

      def text?
        type == TEXT_NODE
      end

      def read_only?
        # According to gdome2, these are read-only node types
        [NOTATION_NODE, ENTITY_NODE, ENTITY_DECL].include?(type)
      end

      def element?
        type == ELEMENT_NODE
      end
      alias :elem? :element?

      def to_s
        document.xml? ? to_xml : to_html
      end

      def inner_html
        children.map { |x| x.to_html }.join
      end

      def css_path
        path.split(/\//).map { |part|
          part.length == 0 ? nil : part.gsub(/\[(\d+)\]/, ':nth-of-type(\1)')
        }.compact.join(' > ')
      end

      #  recursively get all namespaces from this node and its subtree
      def collect_namespaces
        # TODO: print warning message if a prefix refers to more than one URI in the document?
        ns = {}
        traverse {|j| ns.merge!(j.namespaces)}
        ns
      end

      ###
      # Get a list of ancestor Node for this Node
      def ancestors
        parents = []

        this_parent = self.parent

        while this_parent != nil
          parents << this_parent
          this_parent = this_parent.parent
        end
        parents
      end

      ####
      # Yields self and all children to +block+ recursively.
      def traverse(&block)
        children.each{|j| j.traverse(&block) }
        block.call(self)
      end

      ####
      #  replace node with the new node in the document.
      def replace(new_node)
        if new_node.is_a?(Document)
          raise ArgumentError, <<-EOERR
Node.replace requires a Node argument, and cannot accept a Document.
(You probably want to select a node from the Document with at() or search(), or create a new Node via Node.new().)
          EOERR
        end
        replace_with_node new_node
      end

      def to_str
        text
      end

      def == other
        return false unless other
        return false unless other.respond_to?(:pointer_id)
        pointer_id == other.pointer_id
      end
    end
  end
end
