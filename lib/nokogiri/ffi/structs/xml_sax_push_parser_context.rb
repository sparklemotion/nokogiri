module Nokogiri
  module LibXML # :nodoc:

    class XmlSaxPushParserContext < FFI::ManagedStruct # :nodoc:

      layout :dummy, :int, 0 # to avoid @layout warnings

      def self.release ptr
        LibXML.xmlFreeParserCtxt(ptr)
      end
    end

  end
end
