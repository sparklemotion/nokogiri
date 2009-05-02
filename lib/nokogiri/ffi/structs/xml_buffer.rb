module Nokogiri
  module LibXML
    class XmlBuffer < FFI::ManagedStruct

      layout(
        :content,       :string,
        :use,           :int,
        :size,          :int
        )

      def self.release ptr
        LibXML.xmlBufferFree(ptr)
      end
    end
  end
end
