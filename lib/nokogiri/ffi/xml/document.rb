module Nokogiri
  module XML
    class Document < Node

      attr_accessor :cstruct # :nodoc:

      def url # :nodoc:
        cstruct[:URL]
      end

      def root=(node) # :nodoc:
        LibXML.xmlDocSetRootElement(cstruct, node.cstruct)
        node
      end

      def root # :nodoc:
        ptr = LibXML.xmlDocGetRootElement(cstruct)
        ptr.null? ? nil : Node.wrap(LibXML::XmlNode.new(ptr))
      end

      def encoding=(encoding) # :nodoc:
        # TODO: if :encoding is already set, then it's probably getting leaked.
        cstruct[:encoding] = LibXML.xmlStrdup(encoding)
      end

      def encoding # :nodoc:
        cstruct[:encoding].read_string
      end

      def self.read_io(io, url, encoding, options) # :nodoc:
        wrap_with_error_handling do
          LibXML.xmlReadIO(IoCallbacks.reader(io), nil, nil, url, encoding, options)
        end
      end

      def self.read_memory(string, url, encoding, options) # :nodoc:
        wrap_with_error_handling do
          LibXML.xmlReadMemory(string, string.length, url, encoding, options)
        end
      end

      def dup(deep = 1) # :nodoc:
        dup_ptr = LibXML.xmlCopyDoc(cstruct, deep)
        return nil if dup_ptr.null?

        # xmlCopyDoc does not preserve document type. wtf?
        cstruct = LibXML::XmlDocumentCast.new(dup_ptr)
        cstruct[:type] = self.type

        self.class.wrap(dup_ptr)
      end

      class << self
        def new(*args) # :nodoc:
          version = args.first || "1.0"
          doc = wrap(LibXML.xmlNewDoc(version))
          doc.send :initialize, *args
          doc
        end

        def wrap(doc_struct) # :nodoc: #
          if doc_struct.is_a?(FFI::Pointer)
            # cast native pointers up into a doc cstruct
            return nil if doc_struct.null?
            doc_struct = LibXML::XmlDocument.new(doc_struct)
          end

          doc                  = self.allocate
          doc.cstruct          = doc_struct
          doc.cstruct.ruby_doc = doc
          doc.instance_eval { @decorators = nil; @node_cache = [] }
          doc.send :initialize
          doc
        end
      end

      private

      class << self
        def wrap_with_error_handling(&block) # :nodoc:
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
end
