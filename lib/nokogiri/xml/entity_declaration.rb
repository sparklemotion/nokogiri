module Nokogiri
  module XML
    class EntityDeclaration < Nokogiri::XML::Node
      ###
      # return attributes.  Always returns +nil+
      def attributes
        nil
      end
    end
  end
end
