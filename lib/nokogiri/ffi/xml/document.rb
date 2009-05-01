module Nokogiri
  module XML
    class Document < Node

      attr_accessor :cstruct

      def url
        cstruct[:URL]
      end

      def root=(node)
        LibXML.xmlDocSetRootElement(cstruct, node.cstruct)
        node
      end

      def root
        ptr = LibXML.xmlDocGetRootElement(cstruct)
        ptr.null? ? nil : Node.wrap(LibXML::XmlNode.new(ptr))
      end

      def encoding=(encoding)
        # TODO: if :encoding is already set, then it's probably getting leaked.
        cstruct[:encoding] = LibXML.xmlStrdup(encoding)
      end

      def encoding
        cstruct[:encoding].read_string
      end

      def self.read_io(io, url, encoding, options)
        wrap_with_error_handling(DOCUMENT_NODE) do
          reader = lambda do |ctx, buffer, len|
            string = io.read(len)
            return 0 if string.nil?
            LibXML.memcpy(buffer, string, string.length)
            string.length
          end
          closer = lambda { |ctx| 0 } # coffee is for closers.
          
          LibXML.xmlReadIO(reader, closer, nil, url, encoding, options)
        end
      end

      def self.read_memory(string, url, encoding, options)
        wrap_with_error_handling(DOCUMENT_NODE) do
          LibXML.xmlReadMemory(string, string.length, url, encoding, options)
        end
      end

      def dup(deep = 1)
        dup_ptr = LibXML.xmlCopyDoc(cstruct, deep)
        return nil if dup_ptr.null?

        # xmlCopyDoc does not preserve document type. wtf?
        cstruct = LibXML::XmlDocumentCast.new(dup_ptr)
        cstruct[:type] = self.type

        Document.wrap(dup_ptr)
      end

      def self.new(*args)
        version = args.first || "1.0"
        Document.wrap(LibXML.xmlNewDoc(version))
      end

      def self.substitute_entities=(entities)
        raise "Document#substitute_entities= not implemented"
      end

      def load_external_subsets=(subsets)
        raise "Document#load_external_subsets= not implemented"
      end

      def self.wrap(ptr) # :nodoc:
        cstruct = LibXML::XmlDocument.new(ptr)
        doc = if cstruct[:type] == HTML_DOCUMENT_NODE
                Nokogiri::HTML::Document.allocate
              else
                allocate
              end
        doc.cstruct = cstruct
        doc.cstruct.ruby_doc = doc
        doc.instance_eval { @decorators = nil }
        doc
      end

      private
      
      def self.wrap_with_error_handling(type, &block)
        error_list = []
        LibXML.xmlInitParser()
        LibXML.xmlResetLastError()
        LibXML.xmlSetStructuredErrorFunc(nil, SyntaxError.error_array_pusher(error_list))

        ptr = yield
        
        LibXML.xmlSetStructuredErrorFunc(nil, nil)

        if ptr.null?
          error = LibXML.xmlGetLastError()
          if error
            raise SyntaxError.wrap(error)
          else
            raise RuntimeError, "Could not parse document"
          end
        end

        document = wrap(ptr)
        document.errors = error_list
        return document
      end

    end
  end
end
