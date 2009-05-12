module Nokogiri
  module XML
    class Reader
      
      attr_accessor :cstruct # :nodoc

      def default? # :nodoc
        LibXML.xmlTextReaderIsDefault(cstruct) == 1
      end

      def value? # :nodoc
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

      def namespaces # :nodoc
        return {} unless attributes?

        ptr = LibXML.xmlTextReaderExpand(cstruct)
        return nil if ptr.null?

        node = Node.wrap(ptr)
        node.namespaces
      end

      def attribute_nodes # :nodoc
        return {} unless attributes?

        ptr = LibXML.xmlTextReaderExpand(cstruct)
        return nil if ptr.null?

        node = Node.wrap(ptr)
        node.attribute_nodes
      end

      def attribute_at(index) # :nodoc
        return nil if index.nil?
        index = index.to_i
        attr_ptr = LibXML.xmlTextReaderGetAttributeNo(cstruct, index)
        return nil if attr_ptr.null?

        attr = attr_ptr.read_string
        LibXML.xmlFree attr_ptr
        attr
      end

      def attribute(name) # :nodoc
        return nil if name.nil?
        attr_ptr = LibXML.xmlTextReaderGetAttribute(cstruct, name.to_s)
        if attr_ptr.null?
          # this section is an attempt to workaround older versions of libxml that
          # don't handle namespaces properly in all attribute-and-friends functions
          prefix = FFI::MemoryPointer.new :pointer
          localname = LibXML.xmlSplitQName2(name, prefix)
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
          LibXML.xmlFree(prefix.read_pointer)
        end
        return nil if attr_ptr.null?

        attr = attr_ptr.read_string
        LibXML.xmlFree(attr_ptr)
        attr
      end

      def attribute_count # :nodoc
        count = LibXML.xmlTextReaderAttributeCount(cstruct)
        count == -1 ? nil : count
      end

      def depth # :nodoc
        val = LibXML.xmlTextReaderDepth(cstruct)
        val == -1 ? nil : val
      end

      def xml_version # :nodoc
        val = LibXML.xmlTextReaderConstXmlVersion(cstruct)
        val.null? ? nil : val.read_string
      end

      def lang # :nodoc
        val = LibXML.xmlTextReaderConstXmlLang(cstruct)
        val.null? ? nil : val.read_string
      end

      def value # :nodoc
        val = LibXML.xmlTextReaderConstValue(cstruct)
        val.null? ? nil : val.read_string
      end

      def prefix # :nodoc
        val = LibXML.xmlTextReaderConstPrefix(cstruct)
        val.null? ? nil : val.read_string
      end

      def namespace_uri # :nodoc
        val = LibXML.xmlTextReaderConstNamespaceUri(cstruct)
        val.null? ? nil : val.read_string
      end

      def local_name # :nodoc
        val = LibXML.xmlTextReaderConstLocalName(cstruct)
        val.null? ? nil : val.read_string
      end

      def name # :nodoc
        val = LibXML.xmlTextReaderConstName(cstruct)
        val.null? ? nil : val.read_string
      end

      def state # :nodoc
        LibXML.xmlTextReaderReadState(cstruct)
      end

      def read # :nodoc
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

      def self.from_memory(buffer, url=nil, encoding=nil, options=0) # :nodoc
        raise(ArgumentError, "string cannot be nil") if buffer.nil?
        reader_ptr = LibXML.xmlReaderForMemory(buffer, buffer.length, url, encoding, options)
        raise(RuntimeError, "couldn't create a reader") if reader_ptr.null?

        reader = allocate
        reader.cstruct = LibXML::XmlTextReader.new(reader_ptr)
        reader.send(:initialize, buffer, url, encoding)
        reader
      end

      def self.from_io(io, url=nil, encoding=nil, options=0) # :nodoc
        raise(ArgumentError, "io cannot be nil") if io.nil?

        reader_ptr = LibXML.xmlReaderForIO(IoCallbacks.reader(io), nil, nil, url, encoding, options)
        raise "couldn't create a parser" if reader_ptr.null?

        reader = allocate
        reader.cstruct = LibXML::XmlTextReader.new(reader_ptr)
        reader.send(:initialize, io, url, encoding)
        reader
      end

    end
  end
end
