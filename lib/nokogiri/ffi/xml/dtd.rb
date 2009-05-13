module Nokogiri
  module XML
    class DTD < Node
      
      def elements # :nodoc:
        internal_attributes :elements
      end

      def entities # :nodoc:
        internal_attributes :entities
      end

      def notations # :nodoc:
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
      def internal_attributes(attr_name) # :nodoc:
        attr_ptr = cstruct[attr_name.to_sym]
        return nil if attr_ptr.null?

        ahash = {}
        proc = lambda do |payload, data, name|
          ahash[name] = Node.wrap(payload)
        end
        LibXML.xmlHashScan(attr_ptr, proc, nil)
        ahash
      end

    end
  end
end
