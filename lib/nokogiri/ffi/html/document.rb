module Nokogiri
  module HTML
    class Document < XML::Document

      attr_accessor :cstruct

      def self.new(uri=nil, external_id=nil)
        Document.wrap(LibXML.htmlNewDoc(uri, external_id))
      end

      def self.read_io(io, url, encoding, options)
        wrap_with_error_handling(HTML_DOCUMENT_NODE) do
          reader = lambda do |ctx, buffer, len|
            string = io.read(len)
            return 0 if string.nil?
            LibXML.memcpy(buffer, string, string.length)
            string.length
          end
          closer = lambda { |ctx| 0 } # coffee is for closers.
          
          LibXML.htmlReadIO(reader, closer, nil, url, encoding, options)
        end
      end

      def self.read_memory(string, url, encoding, options)
        wrap_with_error_handling(HTML_DOCUMENT_NODE) do
          LibXML.htmlReadMemory(string, string.length, url, encoding, options)
        end
      end

      def meta_encoding=(encoding)
        LibXML.htmlSetMetaEncoding(cstruct, encoding)
        encoding
      end

      def meta_encoding
        LibXML.htmlGetMetaEncoding(cstruct)
      end
    end
  end
end
