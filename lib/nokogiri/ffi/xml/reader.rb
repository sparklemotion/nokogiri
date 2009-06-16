module Nokogiri
  module XML
    class Reader

      attr_accessor :cstruct # :nodoc:
      attr_accessor :reader_callback # :nodoc:

      def default? # :nodoc:
        LibXML.xmlTextReaderIsDefault(cstruct) == 1
      end

      def value? # :nodoc:
        LibXML.xmlTextReaderHasValue(cstruct) == 1
      end

      def attributes? # :nodoc:
        #  this implementation of xmlTextReaderHasAttributes explicitly includes
        #  namespaces and properties, because some earlier versions ignore
        #  namespaces.
        node_ptr = LibXML.xmlTextReaderCurrentNode(cstruct)
        return false if node_ptr.null?
        node = LibXML::XmlNode.new node_ptr
        node[:type] == Node::ELEMENT_NODE && (!node[:properties].null? || !node[:nsDef].null?)
      end

      def namespaces # :nodoc:
        return {} unless attributes?

        ptr = LibXML.xmlTextReaderExpand(cstruct)
        return nil if ptr.null?

        node = Node.wrap(ptr)
        Reader.node_namespaces(node)
      end

      def attribute_nodes # :nodoc:
        return {} unless attributes?

        ptr = LibXML.xmlTextReaderExpand(cstruct)
        return nil if ptr.null?
        node_struct = LibXML::XmlNode.new(ptr)

        # FIXME I'm not sure if this is correct.....  I don't really like pointing
        # at this document, but I have to because of the assertions in
        # the node wrapping code.
        unless node_struct.document.ruby_doc
          doc_struct = LibXML::XmlDocumentCast.new(node_struct[:doc])
          doc_struct.alloc_tuple
          doc = Document.wrap(doc_struct)
        end

        node = Node.wrap(node_struct)
        node.attribute_nodes
      end

      def attribute_at(index) # :nodoc:
        return nil if index.nil?
        index = index.to_i
        attr_ptr = LibXML.xmlTextReaderGetAttributeNo(cstruct, index)
        return nil if attr_ptr.null?

        attr = attr_ptr.read_string
        LibXML.xmlFree attr_ptr
        attr
      end

      def attribute(name) # :nodoc:
        return nil if name.nil?
        attr_ptr = LibXML.xmlTextReaderGetAttribute(cstruct, name.to_s)
        if attr_ptr.null?
          # this section is an attempt to workaround older versions of libxml that
          # don't handle namespaces properly in all attribute-and-friends functions
          prefix_ptr = FFI::MemoryPointer.new :pointer
          localname = LibXML.xmlSplitQName2(name, prefix_ptr)
          prefix = prefix_ptr.get_pointer(0)
          if ! localname.null?
            attr_ptr = LibXML.xmlTextReaderLookupNamespace(cstruct, localname.read_string)
            LibXML.xmlFree(localname)
          else
            if prefix.null? || prefix.read_string.length == 0
              attr_ptr = LibXML.xmlTextReaderLookupNamespace(cstruct, nil)
            else
              attr_ptr = LibXML.xmlTextReaderLookupNamespace(cstruct, prefix.read_string)
            end
          end
          LibXML.xmlFree(prefix)
        end
        return nil if attr_ptr.null?

        attr = attr_ptr.read_string
        LibXML.xmlFree(attr_ptr)
        attr
      end

      def attribute_count # :nodoc:
        count = LibXML.xmlTextReaderAttributeCount(cstruct)
        count == -1 ? nil : count
      end

      def depth # :nodoc:
        val = LibXML.xmlTextReaderDepth(cstruct)
        val == -1 ? nil : val
      end

      def xml_version # :nodoc:
        val = LibXML.xmlTextReaderConstXmlVersion(cstruct)
        val.null? ? nil : val.read_string
      end

      def lang # :nodoc:
        val = LibXML.xmlTextReaderConstXmlLang(cstruct)
        val.null? ? nil : val.read_string
      end

      def value # :nodoc:
        val = LibXML.xmlTextReaderConstValue(cstruct)
        val.null? ? nil : val.read_string
      end

      def prefix # :nodoc:
        val = LibXML.xmlTextReaderConstPrefix(cstruct)
        val.null? ? nil : val.read_string
      end

      def namespace_uri # :nodoc:
        val = LibXML.xmlTextReaderConstNamespaceUri(cstruct)
        val.null? ? nil : val.read_string
      end

      def local_name # :nodoc:
        val = LibXML.xmlTextReaderConstLocalName(cstruct)
        val.null? ? nil : val.read_string
      end

      def name # :nodoc:
        val = LibXML.xmlTextReaderConstName(cstruct)
        val.null? ? nil : val.read_string
      end

      def state # :nodoc:
        LibXML.xmlTextReaderReadState(cstruct)
      end

      def read # :nodoc:
        error_list = self.errors

        LibXML.xmlSetStructuredErrorFunc(nil, SyntaxError.error_array_pusher(error_list))
        ret = LibXML.xmlTextReaderRead(cstruct)
        LibXML.xmlSetStructuredErrorFunc(nil, nil)

        return self if ret == 1
        return nil if ret == 0

        error = LibXML.xmlGetLastError()
        if error
          raise SyntaxError.wrap(error)
        else
          raise RuntimeError, "Error pulling: #{ret}"
        end

        nil
      end

      def self.from_memory(buffer, url=nil, encoding=nil, options=0) # :nodoc:
        raise(ArgumentError, "string cannot be nil") if buffer.nil?

        memory = FFI::MemoryPointer.new(buffer.length) # we need to manage native memory lifecycle
        memory.put_bytes(0, buffer)
        reader_ptr = LibXML.xmlReaderForMemory(memory, memory.total, url, encoding, options)
        raise(RuntimeError, "couldn't create a reader") if reader_ptr.null?

        reader = allocate
        reader.cstruct = LibXML::XmlTextReader.new(reader_ptr)
        reader.send(:initialize, memory, url, encoding)
        reader
      end

      def self.from_io(io, url=nil, encoding=nil, options=0) # :nodoc:
        raise(ArgumentError, "io cannot be nil") if io.nil?

        cb = IoCallbacks.reader(io) # we will keep a reference to prevent it from being GC'd
        reader_ptr = LibXML.xmlReaderForIO(cb, nil, nil, url, encoding, options)
        raise "couldn't create a parser" if reader_ptr.null?

        reader = allocate
        reader.cstruct = LibXML::XmlTextReader.new(reader_ptr)
        reader.send(:initialize, io, url, encoding)
        reader.reader_callback = cb
        reader
      end

      private

      class << self
        def node_namespaces(node) # :nodoc:
          cstruct = node.cstruct
          ahash = {}
          return ahash unless cstruct[:type] == Node::ELEMENT_NODE
          ns = cstruct[:nsDef]
          while ! ns.null?
            ns_cstruct = LibXML::XmlNs.new(ns)
            prefix = ns_cstruct[:prefix]
            key = if prefix.nil? || prefix.empty?
                    "xmlns"
                  else
                    "xmlns:#{prefix}"
                  end
            ahash[key] = ns_cstruct[:href] # TODO: encoding?
            ns = ns_cstruct[:next] # TODO: encoding?
          end
          ahash
        end
      end
      
    end
  end
end
