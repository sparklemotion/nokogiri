module Nokogiri
  module HTML
    class Document < XML::Document

      attr_accessor :cstruct # :nodoc

      def self.new(uri=nil, external_id=nil) # :nodoc
        Document.wrap(LibXML.htmlNewDoc(uri, external_id))
      end

      def self.read_io(io, url, encoding, options) # :nodoc
        wrap_with_error_handling(HTML_DOCUMENT_NODE) do
          LibXML.htmlReadIO(IoCallbacks.reader(io), IoCallbacks.closer(io), nil, url, encoding, options)
        end
      end

      def self.read_memory(string, url, encoding, options) # :nodoc
        wrap_with_error_handling(HTML_DOCUMENT_NODE) do
          LibXML.htmlReadMemory(string, string.length, url, encoding, options)
        end
      end

      def meta_encoding=(encoding) # :nodoc
        LibXML.htmlSetMetaEncoding(cstruct, encoding)
        encoding
      end

      def meta_encoding # :nodoc
        LibXML.htmlGetMetaEncoding(cstruct)
      end
    end
  end
end
