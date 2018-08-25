require 'nokogiri'

module Nokogiri
  # Monkey patch
  module XML
    class Node
      # HTML elements can have attributes that contain colons.
      # Nokogiri::XML::Node#[]= treats names with colons as a prefixed QName
      # and tries to create an attribute in a namespace. This is especially
      # annoying with attribute names like xml:lang since libxml2 will
      # actually create the xml namespace if it doesn't exist already.
      def add_child_node_and_reparent_attrs node
        add_child_node(node)
        node.attribute_nodes.find_all { |a| a.namespace }.each do |attr|
          attr.remove
          node[attr.name] = attr.value
        end
      end
    end
  end
end
