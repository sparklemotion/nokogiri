# :stopdoc:
module Nokogiri
  module XML
    class EntityDecl < Nokogiri::XML::Node
      def content
        cstruct[:content]
      end

      def entity_type
        cstruct[:etype]
      end

      def external_id
        cstruct[:external_id]
      end

      def system_id
        cstruct[:system_id]
      end

      def original_content
        cstruct[:orig]
      end
    end
  end
end
# :startdoc:
