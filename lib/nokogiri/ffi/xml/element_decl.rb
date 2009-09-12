# :stopdoc:
module Nokogiri
  module XML
    class ElementDecl < Nokogiri::XML::Node
      def element_type
        cstruct[:etype]
      end
    end
  end
end
# :startdoc:
