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

      def search(*search_paths)
        sets = search_paths.map { |search_path|
          set = XPath.new(self, search_path).node_set
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
      alias :/ :search

      def [](property)
        return nil unless key?(property)
        get(property)
      end

      def next
        next_sibling
      end

      def has_attribute?(property)
        key? property
      end

      alias :get_attribute :[]
      def set_attribute(name, value)
        self[name] = value
      end

      def remove_attribute name
        remove(name)
      end

      def inner_text
        content
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
          part.length == 0 ? nil : part.gsub(/\[(\d+)\]/, ':nth-child(\1)')
        }.compact.join(' > ')
      end

      def xpath
        path
      end
    end
  end
end
