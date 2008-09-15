module Nokogiri
  module XML
    class Document < Node
      attr_accessor :node_decorators

      ###
      # Apply any decorators to +node+
      def decorate(node)
        (node_decorators || []).each do |klass|
          node.extend(klass)
        end
      end

      def to_xml
        serialize
      end
    end
  end
end
