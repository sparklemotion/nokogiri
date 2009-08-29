module Nokogiri
  module XML
    ###
    # Represents an attribute declaration in a DTD
    class AttributeDecl < Nokogiri::XML::Node
      undef_method :attribute_nodes
      undef_method :attributes
      undef_method :namespace
      undef_method :namespace_definitions
      undef_method :line

      def inspect
        "#<#{self.class.name}:#{sprintf("0x%x", self.object_id)} #{self.to_s.inspect}>"
      end
    end
  end
end
