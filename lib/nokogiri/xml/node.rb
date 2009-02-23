require 'stringio'
require 'nokogiri/xml/node/save_options'

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

      # The Document associated with this Node.
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
      #   }.new)
      #
      def xpath *paths
        # Pop off our custom function handler if it exists
        handler = ![
          Hash, String, Symbol
        ].include?(paths.last.class) ? paths.pop : nil

        ns = paths.last.is_a?(Hash) ? paths.pop : document.root.namespaces

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

        ns = rules.last.is_a?(Hash) ? rules.pop : document.root.namespaces

        rules = rules.map { |rule|
          CSS.xpath_for(rule, :prefix => ".//", :ns => ns)
        }.flatten.uniq + [ns, handler].compact

        xpath(*rules)
      end

      ###
      # Search for the first occurrence of +path+.
      # Returns nil if nothing is found, otherwise a Node.
      def at path, ns = document.root.namespaces
        search(path, ns).first
      end

      ###
      # Get the attribute value for the attribute +name+
      def [](name)
        return nil unless key?(name)
        get(name)
      end

      alias :next           :next_sibling
      alias :previous       :previous_sibling
      alias :remove         :unlink
      alias :get_attribute  :[]
      alias :set_attribute  :[]=
      alias :text           :content
      alias :inner_text     :content
      alias :has_attribute? :key?
      alias :<<             :add_child
      alias :name           :node_name
      alias :name=          :node_name=
      alias :type           :node_type
      alias :to_str         :text

      ####
      # Returns a hash containing the node's attributes.  The key is the
      # attribute name, the value is the string value of the attribute.
      def attributes
        Hash[*(attribute_nodes.map { |node|
          [node.node_name, node]
        }.flatten)]
      end

      ###
      # Get the attribute values for this Node.
      def values
        attribute_nodes.map { |node| node.value }
      end

      ###
      # Get the attribute names for this Node.
      def keys
        attribute_nodes.map { |node| node.node_name }
      end

      ###
      # Iterate over each attribute name and value pair for this Node.
      def each &block
        attribute_nodes.each { |node|
          block.call(node.node_name, node.value)
        }
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

      ###
      # Test to see if this Node is equal to +other+
      def == other
        return false unless other
        return false unless other.respond_to?(:pointer_id)
        pointer_id == other.pointer_id
      end

      ###
      # Serialize Node using +encoding+ and +save_options+.  Save options 
      # can also be set using a block. See SaveOptions.
      #
      # These two statements are equivalent:
      #
      #  node.serialize('UTF-8', FORMAT | AS_XML)
      #
      # or
      #
      #   node.serialize('UTF-8') do |config|
      #     config.format.as_xml
      #   end
      #
      def serialize encoding = nil, save_options = SaveOptions::FORMAT, &block
        io = StringIO.new
        write_to io, encoding, save_options, &block
        io.rewind
        io.read
      end

      ###
      # Serialize this Node to HTML using +encoding+
      def to_html encoding = nil
        # FIXME: this is a hack around broken libxml versions
        return dump_html if %w[2 6] === LIBXML_VERSION.split('.')[0..1]

        serialize(encoding, SaveOptions::FORMAT |
                            SaveOptions::NO_DECLARATION |
                            SaveOptions::NO_EMPTY_TAGS |
                            SaveOptions::AS_HTML)
      end

      ###
      # Serialize this Node to XML using +encoding+
      def to_xml encoding = nil
        serialize(encoding, SaveOptions::FORMAT | SaveOptions::AS_XML)
      end

      ###
      # Serialize this Node to XML using +encoding+
      def to_xhtml encoding = nil
        # FIXME: this is a hack around broken libxml versions
        return dump_html if %w[2 6] === LIBXML_VERSION.split('.')[0..1]

        serialize(encoding, SaveOptions::FORMAT |
                            SaveOptions::NO_DECLARATION |
                            SaveOptions::NO_EMPTY_TAGS |
                            SaveOptions::AS_XHTML)
      end

      ###
      # Write Node to +io+ with +encoding+ and +save_options+
      def write_to io, encoding = nil, save_options = SaveOptions::FORMAT
        config = SaveOptions.new(save_options)
        yield config if block_given?

        native_write_to(io, encoding, config.options)
      end

      ###
      # Write Node as HTML to +io+ with +encoding+
      def write_html_to io, encoding = nil
        write_to io, encoding, SaveOptions::FORMAT |
          SaveOptions::NO_DECLARATION |
          SaveOptions::NO_EMPTY_TAGS |
          SaveOptions::AS_HTML
      end

      ###
      # Write Node as XHTML to +io+ with +encoding+
      def write_xhtml_to io, encoding = nil
        write_to io, encoding, SaveOptions::FORMAT |
          SaveOptions::NO_DECLARATION |
          SaveOptions::NO_EMPTY_TAGS |
          SaveOptions::AS_XHTML
      end

      ###
      # Write Node as XML to +io+ with +encoding+
      def write_xml_to io, encoding = nil
        write_to io, encoding, SaveOptions::FORMAT | SaveOptions::AS_XML
      end

      def self.new_from_str string
        $stderr.puts("This method is deprecated and will be removed in 1.2.0 or by March 1, 2009. Instead, use Nokogiri::HTML.fragment()")
        Nokogiri::HTML.fragment(string).first
      end
    end
  end
end
