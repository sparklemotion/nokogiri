module Nokogiri
  module XML
    class DTD < Node
      # :stopdoc:
      def validate document
        error_list = []
        ctxt = LibXML.xmlNewValidCtxt

        LibXML.xmlSetStructuredErrorFunc(nil, SyntaxError.error_array_pusher(error_list))
        LibXML.xmlValidateDtd ctxt, document.cstruct, cstruct

        LibXML.xmlSetStructuredErrorFunc nil, nil

        LibXML.xmlFreeValidCtxt ctxt

        error_list
      end

      def elements
        internal_attributes :elements
      end

      def entities
        internal_attributes :entities
      end

      def notations
        attr_ptr = cstruct[:notations]
        return nil if attr_ptr.null?

        ahash = {}
        proc = lambda do |payload, data, name|
          notation_cstruct = LibXML::XmlNotation.new(payload)
          ahash[name] = Notation.new(notation_cstruct[:name], notation_cstruct[:PublicID],
                                     notation_cstruct[:SystemID])
        end
        LibXML.xmlHashScan(attr_ptr, proc, nil)
        ahash
      end

      private

      def internal_attributes attr_name
        attr_ptr = cstruct[attr_name.to_sym]
        return nil if attr_ptr.null?

        ahash = {}
        proc = lambda do |payload, data, name|
          ahash[name] = Node.wrap(payload)
        end
        LibXML.xmlHashScan(attr_ptr, proc, nil)
        ahash
      end

      # :startdoc:
    end
  end
end
