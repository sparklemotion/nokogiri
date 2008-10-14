module Nokogiri
  module XML
    class Node
      COMMENT_NODE = 8
      DOCUMENT_NODE = 9
      HTML_DOCUMENT_NODE = 13
      DTD_NODE = 14
      ELEMENT_DECL = 15
      ATTRIBUTE_DECL = 16
      ENTITY_DECL = 17
      NAMESPACE_DECL = 18
      XINCLUDE_START = 19
      XINCLUDE_END = 20
      DOCB_DOCUMENT_NODE = 21

      def decorate!
        document.decorate(self) if document
      end

      def children
        list = NodeSet.new
        list.document = document
        document.decorate(list)

        first = self.child
        return list unless first # Empty list

        list << first unless first.blank?
        while first = first.next
          list << first unless first.blank?
        end
        list
      end

      def search *paths
        ns = paths.last.is_a?(Hash) ? paths.pop : {}
        xpath(*(paths.map { |path|
          path =~ /^(\.\/|\/)/ ? path : CSS::Parser.parse(path).map { |ast|
            ast.to_xpath
          }
        }.flatten.uniq) + [ns])
      end
      alias :/ :search

      def xpath *paths
        ns = paths.last.is_a?(Hash) ? paths.pop : {}

        return NodeSet.new unless document.root

        sets = paths.map { |path|
          ctx = XPathContext.new(self)
          ctx.register_namespaces(ns)
          set = ctx.evaluate(path).node_set
          set.document = document
          document.decorate(set)
          set
        }
        return sets.first if sets.length == 1

        NodeSet.new do |combined|
          document.decorate(combined)
          sets.each do |set|
            set.each do |node|
              combined << node
            end
          end
        end
      end

      def css *rules
        xpath(*(rules.map { |rule|
          CSS::Parser.parse(rule).map { |ast| ast.to_xpath }
        }.flatten.uniq))
      end

      def at path, ns = {}
        search("#{path}", ns).first
      end

      def [](property)
        return nil unless key?(property)
        get(property)
      end

      def next
        next_sibling
      end

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

      def comment?
        type == COMMENT_NODE
      end

      def xml?
        type == DOCUMENT_NODE
      end

      def html?
        type == HTML_DOCUMENT_NODE
      end

      def to_html
        to_xml
      end
      alias :to_s :to_html
      alias :inner_html :to_html

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

      ####
      # Yields self and all children to +block+ recursively.
      def traverse(&block)
        children.each{|j| j.traverse(&block) }
        block.call(self)
      end
    end
  end
end
