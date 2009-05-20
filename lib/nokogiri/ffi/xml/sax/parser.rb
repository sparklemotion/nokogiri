module Nokogiri
  module XML
    module SAX
      class Parser
        
        attr_accessor :cstruct # :nodoc:

        def parse_memory(data) # :nodoc:
          raise(ArgumentError, 'data cannot be nil') if data.nil?
          LibXML.xmlSAXUserParseMemory(cstruct, nil, data, data.length)
          data
        end

        def native_parse_io(io, encoding) # :nodoc:
          sax_ctx = LibXML.xmlCreateIOParserCtxt(cstruct, nil, IoCallbacks.reader(io), nil, nil, encoding)
          LibXML.xmlParseDocument(sax_ctx)
          LibXML.xmlFreeParserCtxt(sax_ctx)
          io
        end

        def native_parse_file(data) # :nodoc:
          LibXML.xmlSAXUserParseFile(cstruct, nil, data)
        end

        def self.new(doc = XML::SAX::Document.new, encoding = 'ASCII') # :nodoc:
          parser = allocate
          parser.document = doc
          parser.encoding = encoding
          parser.cstruct = LibXML::XmlSaxHandler.allocate
          parser.send(:setup_lambdas)
          parser
        end

      private

        def setup_lambdas # :nodoc:
          @closures = {} # we need to keep references to the closures to avoid GC
          
          [ :startDocument, :endDocument, :startElement, :endElement, :characters,
            :comment, :warning, :error, :cdataBlock, :startElementNs, :endElementNs ].each do |sym|
            @closures[sym] = lambda { |*args| send("__internal__#{sym}", *args) } # "i'm your private dancer", etc.
          end

          @closures.each { |k,v| cstruct[k] = v }

          cstruct[:initialized] = Nokogiri::LibXML::XmlSaxHandler::XML_SAX2_MAGIC
        end

        def __internal__startDocument(_) # :nodoc:
          @document.start_document
        end

        def __internal__endDocument(_) # :nodoc:
          @document.end_document
        end

        def __internal__startElement(_, name, attributes) # :nodoc:
          attrs = []
          unless attributes.null?
            j = 0
            while ! (value = attributes.get_pointer(LibXML.pointer_offset(j))).null?
              attrs << value.read_string
              j += 1
            end
          end
          @document.start_element name, attrs
        end

        def __internal__endElement(_, name) # :nodoc:
          @document.end_element name
        end

        def __internal__characters(_, data, data_length) # :nodoc:
          @document.characters data.slice(0, data_length)
        end

        def __internal__comment(_, data) # :nodoc:
          @document.comment data
        end

        def __internal__warning(_, msg) # :nodoc:
          # TODO: vasprintf here
          @document.warning(msg)
        end

        def __internal__error(_, msg) # :nodoc:
          # TODO: vasprintf here
          @document.error(msg)
        end

        def __internal__cdataBlock(_, data, data_length) # :nodoc:
          @document.cdata_block data.slice(0, data_length)
        end

        def __internal__startElementNs(_, localname, prefix, uri, nb_namespaces, namespaces, nb_attributes, nb_defaulted, attributes) # :nodoc:
          localname = localname.null? ? nil : localname.read_string
          prefix    = prefix   .null? ? nil : prefix   .read_string
          uri       = uri      .null? ? nil : uri      .read_string

          attr_hash = {}
          ns_hash   = {}

          if ! attributes.null?
            # Each attribute is an array of [localname, prefix, URI, value, end]
            (0..(nb_attributes-1)*5).step(5) do |j|
              key          = attributes.get_pointer(LibXML.pointer_offset(j)).read_string
              value_length = attributes.get_pointer(LibXML.pointer_offset(j+4)).address \
                           - attributes.get_pointer(LibXML.pointer_offset(j+3)).address
              value        = attributes.get_pointer(LibXML.pointer_offset(j+3)).get_string(0, value_length)
              attr_hash[key] = value
            end
          end

          if ! namespaces.null?
            (0..(nb_namespaces-1)*2).step(2) do |j|
              key   = namespaces.get_pointer(LibXML.pointer_offset(j))
              key   = key.null?   ? nil : key.read_string
              value = namespaces.get_pointer(LibXML.pointer_offset(j+1))
              value = value.null? ? nil : value.read_string
              ns_hash[key] = value
            end
          end

          @document.start_element_ns(localname, attr_hash, prefix, uri, ns_hash)

          if @document.respond_to?(:start_element)
            name = prefix ? "#{prefix}:#{localname}" : localname
            @document.start_element(name, attr_hash.to_a.flatten)
          end
        end

        def __internal__endElementNs(_, localname, prefix, uri) # :nodoc:
          localname = localname.null? ? nil : localname.read_string
          prefix    = prefix   .null? ? nil : prefix   .read_string
          uri       = uri      .null? ? nil : uri      .read_string

          @document.end_element_ns(localname, prefix, uri)

          if @document.respond_to?(:end_element)
            name = prefix ? "#{prefix}:#{localname}" : localname
            @document.end_element(name)
          end
        end

      end
    end
  end
end
