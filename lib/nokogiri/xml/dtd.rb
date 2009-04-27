module Nokogiri
  module XML
    class DTD < Nokogiri::XML::Node
      ###
      # Return attributes for DTD.  Always returns +nil+
      def attributes
        nil
      end
    end
  end
end
