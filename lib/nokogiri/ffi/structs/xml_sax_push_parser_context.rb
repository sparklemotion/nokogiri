module Nokogiri
  # :stopdoc:
  module LibXML
    class XmlSaxPushParserContext < FFI::ManagedStruct

      layout :dummy, :int, 0 # to avoid @layout warnings

      def self.release ptr
        LibXML.xmlFreeParserCtxt(ptr)
      end
    end

  end
  # :startdoc:
end
