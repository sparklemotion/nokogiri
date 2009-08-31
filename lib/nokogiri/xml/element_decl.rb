module Nokogiri
  module XML
    class ElementDecl < Nokogiri::XML::Node
      undef_method :namespace
      undef_method :namespace_definitions
      undef_method :line

      # FIXME we need an element content method, but I don't want to implement
      # it right now.
      undef_method :content

      def inspect
        "#<#{self.class.name}:#{sprintf("0x%x", object_id)} #{to_s.inspect}>"
      end
    end
  end
end
