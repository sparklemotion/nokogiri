module Nokogiri
  module XML
    class Schema

      attr_accessor :cstruct # :nodoc:

      def validate_document(document) # :nodoc:
        errors = []

        ctx = LibXML.xmlSchemaNewValidCtxt(cstruct)
        raise RuntimeError.new("Could not create a validation context") if ctx.null?

        LibXML.xmlSchemaSetValidStructuredErrors(ctx,
          SyntaxError.error_array_pusher(errors), nil) unless Nokogiri.is_2_6_16?

        LibXML.xmlSchemaValidateDoc(ctx, document.cstruct)

        LibXML.xmlSchemaFreeValidCtxt(ctx)

        errors
      end
      private :validate_document

      def self.read_memory(content) # :nodoc:
        ctx = LibXML.xmlSchemaNewMemParserCtxt(content, content.length)

        errors = []

        LibXML.xmlSetStructuredErrorFunc(nil, SyntaxError.error_array_pusher(errors))
        LibXML.xmlSchemaSetParserStructuredErrors(ctx, SyntaxError.error_array_pusher(errors), nil) unless Nokogiri.is_2_6_16?

        schema_ptr = LibXML.xmlSchemaParse(ctx)

        LibXML.xmlSetStructuredErrorFunc(nil, nil)
        LibXML.xmlSchemaFreeParserCtxt(ctx)

        if schema_ptr.null?
          error = LibXML.xmlGetLastError
          if error
            raise SyntaxError.wrap(error)
          else
            raise RuntimeError, "Could not parse document"
          end
        end

        schema = allocate
        schema.cstruct = LibXML::XmlSchema.new schema_ptr
        schema.errors = errors
        schema
      end

    end
  end
end

