
module Nokogiri
  module LibXML

    def self.expand_library_path(library)
      return File.expand_path(library) if library =~ %r{^[^/].*/}

      dirs = ENV['LD_LIBRARY_PATH'].split(':') + ['/opt/local/lib', '/usr/local/lib', '/usr/lib']

      library = Dir[ *( dirs.collect {|dir| File.join(dir, "#{library}.{so,dylib}")} ) ].first

      raise "Couldn't find #{library}" unless library

      library
    end

    extend FFI::Library
    ffi_lib expand_library_path('libxml2')
    ffi_lib expand_library_path('libxslt')
    ffi_lib expand_library_path('libexslt')

    # useful callback signatures
    callback :syntax_error_handler, [:pointer, :pointer], :void
    callback :generic_error_handler, [:pointer, :string], :void
    callback :io_write_callback, [:pointer, :string, :int], :int
    callback :io_read_callback, [:pointer, :pointer, :int], :int
    callback :io_close_callback, [:pointer], :int
    callback :hash_copier_callback, [:pointer, :pointer, :string], :void
    callback :xpath_callback, [:pointer, :int], :void
    callback :xpath_lookup_callback, [:pointer, :string, :pointer], :xpath_callback
    callback :start_document_sax_func, [:pointer], :void
    callback :end_document_sax_func, [:pointer], :void
    callback :start_element_sax_func, [:pointer, :string, :pointer], :void
    callback :end_element_sax_func, [:pointer, :string], :void
    callback :characters_sax_func, [:pointer, :string, :int], :void
    callback :comment_sax_func, [:pointer, :string], :void
    callback :warning_sax_func, [:pointer, :string], :void
    callback :error_sax_func, [:pointer, :string], :void
    callback :cdata_block_sax_func, [:pointer, :string, :int], :void

    # libc
    attach_function :calloc, [:int, :int], :pointer
    attach_function :free, [:pointer], :void
    attach_function :memcpy, [:pointer, :pointer, :int], :pointer

    # HTMLparser.c
    attach_function :htmlReadMemory, [:string, :int, :string, :string, :int], :pointer
    attach_function :htmlReadIO, [:io_read_callback, :io_close_callback, :pointer, :string, :string, :int], :pointer
    attach_function :htmlNewDoc, [:string, :string], :pointer
    attach_function :htmlTagLookup, [:string], :pointer
    attach_function :htmlEntityLookup, [:string], :pointer
    attach_function :htmlSAXParseFile, [:string, :pointer, :pointer, :pointer], :pointer # second arg 'encoding' should be a string, but we assign it as a pointer elsewhere
    attach_function :htmlSAXParseDoc, [:pointer, :pointer, :pointer, :pointer], :pointer # second arg 'encoding' should be a string, but we assign it as a pointer elsewhere

    # HTMLtree.c
    attach_function :htmlDocDumpMemory, [:pointer, :pointer, :pointer], :void
    attach_function :htmlNodeDump, [:pointer, :pointer, :pointer], :int
    attach_function :htmlGetMetaEncoding, [:pointer], :string # returns const char*
    attach_function :htmlSetMetaEncoding, [:pointer, :string], :void

    # parser.c
    attach_function :xmlReadMemory, [:string, :int, :string, :string, :int], :pointer
    attach_function :xmlInitParser, [], :void
    attach_function :xmlReadIO, [:io_read_callback, :io_close_callback, :pointer, :string, :string, :int], :pointer
    attach_function :xmlCreateIOParserCtxt, [:pointer, :pointer, :io_read_callback, :io_close_callback, :pointer, :int], :pointer
    attach_function :xmlSAXUserParseMemory, [:pointer, :pointer, :string, :int], :int
    attach_function :xmlSAXUserParseFile, [:pointer, :pointer, :string], :int
    attach_function :xmlParseDocument, [:pointer], :int
    attach_function :xmlFreeParserCtxt, [:pointer], :void
    attach_function :xmlCreatePushParserCtxt, [:pointer, :pointer, :string, :int, :string], :pointer
    attach_function :xmlParseChunk, [:pointer, :string, :int, :int], :int

    # tree.c
    attach_function :xmlNewDoc, [:string], :pointer
    attach_function :xmlNewDocFragment, [:pointer], :pointer
    attach_function :xmlDocGetRootElement, [:pointer], :pointer
    attach_function :xmlDocSetRootElement, [:pointer, :pointer], :pointer
    attach_function :xmlCopyDoc, [:pointer, :int], :pointer
    attach_function :xmlFreeDoc, [:pointer], :void
    attach_function :xmlSetTreeDoc, [:pointer, :pointer], :void
    attach_function :xmlNewReference, [:pointer, :string], :pointer
    attach_function :xmlNewNode, [:pointer, :string], :pointer
    attach_function :xmlCopyNode, [:pointer, :int], :pointer
    attach_function :xmlDocCopyNode, [:pointer, :pointer, :int], :pointer
    attach_function :xmlReplaceNode, [:pointer, :pointer], :pointer
    attach_function :xmlUnlinkNode, [:pointer], :void
    attach_function :xmlAddChild, [:pointer, :pointer], :pointer
    attach_function :xmlAddNextSibling, [:pointer, :pointer], :pointer
    attach_function :xmlAddPrevSibling, [:pointer, :pointer], :pointer
    attach_function :xmlIsBlankNode, [:pointer], :int
    attach_function :xmlHasProp, [:pointer, :string], :pointer
    attach_function :xmlGetProp, [:pointer, :string], :pointer # returns char* that must be freed
    attach_function :xmlSetProp, [:pointer, :string, :string], :pointer
    attach_function :xmlRemoveProp, [:pointer], :int
    attach_function :xmlNodeSetContent, [:pointer, :string], :void
    attach_function :xmlNodeGetContent, [:pointer], :pointer # returns char* that must be freed
    attach_function :xmlNodeSetName, [:pointer, :string], :void
    attach_function :xmlGetNodePath, [:pointer], :pointer
    attach_function :xmlNewCDataBlock, [:pointer, :string, :int], :pointer
    attach_function :xmlNewDocComment, [:pointer, :string], :pointer
    attach_function :xmlNewDocPI, [:pointer, :string, :string], :pointer
    attach_function :xmlNewText, [:string], :pointer
    attach_function :xmlFreeNode, [:pointer], :void
    attach_function :xmlFreeNodeList, [:pointer], :void
    attach_function :xmlEncodeEntitiesReentrant, [:pointer, :string], :pointer # returns char* that must be freed
    attach_function :xmlStringGetNodeList, [:pointer, :pointer], :pointer # second arg should be a :string, but we only ship the results of xmlEncodeEntitiesReentrant, so let's optimize.
    attach_function :xmlNewNs, [:pointer, :string, :string], :pointer
    attach_function :xmlNewNsProp, [:pointer, :pointer, :string, :string], :pointer
    attach_function :xmlSearchNsByHref, [:pointer, :pointer, :string], :pointer
    attach_function :xmlGetIntSubset, [:pointer], :pointer
    attach_function :xmlBufferCreate, [], :pointer
    attach_function :xmlBufferFree, [:pointer], :void
    attach_function :xmlSplitQName2, [:string, :pointer], :pointer # returns char* that must be freed
    attach_function :xmlNewDocProp, [:pointer, :string, :string], :pointer
    attach_function :xmlFreePropList, [:pointer], :void

    # xmlsave.c
    attach_function :xmlDocDumpMemory, [:pointer, :pointer, :pointer], :void
    attach_function :xmlNodeDump, [:pointer, :pointer, :pointer, :int, :int], :int
    attach_function :xmlSaveToIO, [:io_write_callback, :io_close_callback, :pointer, :string, :int], :pointer
    attach_function :xmlSaveTree, [:pointer, :pointer], :int
    attach_function :xmlSaveClose, [:pointer], :int
    attach_function :xmlSetNs, [:pointer, :pointer], :void

    # parserInternals.c
    attach_function :xmlSubstituteEntitiesDefault, [:int], :int

    # entities.c
    attach_function :xmlEncodeSpecialChars, [:pointer, :string], :pointer # returns char* that must be freed

    # globals.c
    attach_function :__xmlParserVersion, [], :pointer
    attach_function :__xmlIndentTreeOutput, [], :pointer
    attach_function :__xmlTreeIndentString, [], :pointer

    # xpath.c
    attach_function :xmlXPathInit, [], :void
    attach_function :xmlXPathNewContext, [:pointer], :pointer
    attach_function :xmlXPathFreeContext, [:pointer], :void
    attach_function :xmlXPathEvalExpression, [:string, :pointer], :pointer
    attach_function :xmlXPathRegisterNs, [:pointer, :string, :string], :int
    attach_function :xmlXPathCmpNodes, [:pointer, :pointer], :int
    attach_function :xmlXPathNodeSetAdd, [:pointer, :pointer], :void
    attach_function :xmlXPathNodeSetCreate, [:pointer], :pointer
    attach_function :xmlXPathFreeNodeSetList, [:pointer], :void
    attach_function :xmlXPathRegisterFuncLookup, [:pointer, :xpath_lookup_callback, :pointer], :void
    attach_function :valuePop, [:pointer], :pointer
    attach_function :valuePush, [:pointer, :pointer], :int
    attach_function :xmlXPathCastToString, [:pointer], :pointer # returns char* that must be freed
    attach_function :xmlXPathNodeSetMerge, [:pointer, :pointer], :pointer
    attach_function :xmlXPathWrapNodeSet, [:pointer], :pointer
    attach_function :xmlXPathWrapCString, [:pointer], :pointer # should take a :string, but we optimize
    attach_function :xmlXPathWrapString, [:pointer], :pointer # should take a :string, but we optimize
    attach_function :xmlXPathNewBoolean, [:int], :pointer
    attach_function :xmlXPathNewFloat, [:double], :pointer

    class << self
      # these functions are implemented as C macros
      def xmlXPathReturnNodeSet(ctx, ns)
        valuePush(ctx, xmlXPathWrapNodeSet(ns))
      end
      def xmlXPathReturnTrue(ctx)
        valuePush(ctx, xmlXPathNewBoolean(1))
      end
      def xmlXPathReturnFalse(ctx)
        valuePush(ctx, xmlXPathNewBoolean(0))
      end
      def xmlXPathReturnString(ctx, str)
        valuePush(ctx, xmlXPathWrapString(str))
      end
      def xmlXPathReturnNumber(ctx, val)
        valuePush(ctx, xmlXPathNewFloat(val))
      end
    end

    # xmlstring.c
    attach_function :xmlStrdup, [:string], :pointer # returns char* that must be freed
    def self.xmlFree(pointer)
      # xmlFree is a C preprocessor macro, not an actual function
      self.free(pointer)
    end

    # error.c
    attach_function :xmlSetStructuredErrorFunc, [:pointer, :syntax_error_handler], :void
    attach_function :xmlSetGenericErrorFunc, [:pointer, :generic_error_handler], :void
    attach_function :xmlResetLastError, [], :void
    attach_function :xmlCopyError, [:pointer, :pointer], :int
    attach_function :xmlGetLastError, [], :pointer

    # hash.c
    attach_function :xmlHashScan, [:pointer, :hash_copier_callback, :pointer], :void

    # xmlreader.c
    attach_function :xmlReaderForMemory, [:pointer, :int, :string, :string, :int], :pointer
    attach_function :xmlTextReaderGetAttribute, [:pointer, :string], :pointer # returns char* that must be freed
    attach_function :xmlTextReaderGetAttributeNo, [:pointer, :int], :pointer # returns char* that must be freed
    attach_function :xmlTextReaderLookupNamespace, [:pointer, :string], :pointer # returns char* that must be freed
    attach_function :xmlTextReaderRead, [:pointer], :int
    attach_function :xmlTextReaderAttributeCount, [:pointer], :int
    attach_function :xmlTextReaderCurrentNode, [:pointer], :pointer
    attach_function :xmlTextReaderExpand, [:pointer], :pointer
    attach_function :xmlTextReaderIsDefault, [:pointer], :int
    attach_function :xmlTextReaderDepth, [:pointer], :int
    attach_function :xmlTextReaderConstXmlLang, [:pointer], :pointer # returns a const char*, but must check for null
    attach_function :xmlTextReaderConstLocalName, [:pointer], :pointer # returns a const char* that is deallocated with the reader
    attach_function :xmlTextReaderConstName, [:pointer], :pointer # returns a const char* that is deallocated with the reader
    attach_function :xmlTextReaderConstNamespaceUri, [:pointer], :pointer # returns a const char* that is deallocated with the reader
    attach_function :xmlTextReaderConstPrefix, [:pointer], :pointer # returns a const char* that is deallocated with the reader
    attach_function :xmlTextReaderConstValue, [:pointer], :pointer # returns a const char* that is deallocated on the next read()
    attach_function :xmlTextReaderConstXmlVersion, [:pointer], :pointer # returns a const char* that is deallocated with the reader
    attach_function :xmlTextReaderReadState, [:pointer], :int
    attach_function :xmlTextReaderHasValue, [:pointer], :int
    attach_function :xmlFreeTextReader, [:pointer], :void
    attach_function :xmlReaderForIO, [:io_read_callback, :io_close_callback, :pointer, :string, :string, :int], :pointer

    # xslt.c
    attach_function :xsltParseStylesheetDoc, [:pointer], :pointer
    attach_function :xsltFreeStylesheet, [:pointer], :void
    attach_function :xsltApplyStylesheet, [:pointer, :pointer, :pointer], :pointer
    attach_function :xsltSaveResultToString, [:pointer, :pointer, :pointer, :pointer], :int

    # exslt.c
    attach_function :exsltRegisterAll, [], :void

    # xmlschemas.c
    attach_function :xmlSchemaNewValidCtxt, [:pointer], :pointer
    attach_function :xmlSchemaSetValidStructuredErrors, [:pointer, :syntax_error_handler, :pointer], :void
    attach_function :xmlSchemaValidateDoc, [:pointer, :pointer], :void
    attach_function :xmlSchemaFreeValidCtxt, [:pointer], :void
    attach_function :xmlSchemaNewMemParserCtxt, [:pointer, :int], :pointer # first arg could be string, but we pass length, so let's optimize
    attach_function :xmlSchemaSetParserStructuredErrors, [:pointer, :syntax_error_handler, :pointer], :void
    attach_function :xmlSchemaParse, [:pointer], :pointer
    attach_function :xmlSchemaFreeParserCtxt, [:pointer], :void

    # relaxng.c
    attach_function :xmlRelaxNGNewValidCtxt, [:pointer], :pointer
    attach_function :xmlRelaxNGSetValidStructuredErrors, [:pointer, :syntax_error_handler, :pointer], :void
    attach_function :xmlRelaxNGValidateDoc, [:pointer, :pointer], :int
    attach_function :xmlRelaxNGFreeValidCtxt, [:pointer], :void
    attach_function :xmlRelaxNGNewMemParserCtxt, [:pointer, :int], :pointer # first arg could be string, but we pass length, so let's optimize
    attach_function :xmlRelaxNGSetParserStructuredErrors, [:pointer, :syntax_error_handler, :pointer], :void
    attach_function :xmlRelaxNGParse, [:pointer], :pointer
    attach_function :xmlRelaxNGFreeParserCtxt, [:pointer], :void
  end

  # initialize constants
  LIBXML_PARSER_VERSION = LibXML.__xmlParserVersion().read_pointer.read_string
  LIBXML_VERSION = lambda {
    LIBXML_PARSER_VERSION =~ /^(\d)(\d{2})(\d{2})$/
    major = $1.to_i
    minor = $2.to_i
    bug   = $3.to_i
    "#{major}.#{minor}.#{bug}"
  }.call
end

require 'nokogiri/version'

Nokogiri::VERSION_INFO['libxml'] = {}
Nokogiri::VERSION_INFO['libxml']['loaded'] = Nokogiri::LIBXML_VERSION
Nokogiri::VERSION_INFO['libxml']['binding'] = 'ffi'
if RUBY_PLATFORM =~ /java/
  Nokogiri::VERSION_INFO['libxml']['platform'] = 'jruby'
else
  Nokogiri::VERSION_INFO['libxml']['platform'] = 'ruby'
end

require 'nokogiri/syntax_error'
require 'nokogiri/xml/syntax_error'

[ "structs/common_node",
  "structs/xml_alloc",
  "structs/xml_document",
  "structs/xml_node",
  "structs/xml_dtd",
  "structs/xml_notation",
  "structs/xml_node_set",
  "structs/xml_xpath_context",
  "structs/xml_xpath",
  "structs/xml_xpath_object.rb",
  "structs/xml_xpath_parser_context.rb",
  "structs/xml_buffer",
  "structs/xml_syntax_error",
  "structs/xml_attr.rb",
  "structs/xml_ns.rb",
  "structs/xml_schema.rb",
  "structs/xml_relax_ng.rb",
  "structs/xml_text_reader.rb",
  "structs/xml_sax_handler.rb",
  "structs/xml_sax_push_parser_context.rb",
  "structs/html_elem_desc",
  "structs/html_entity_desc",
  "structs/xslt_stylesheet.rb",
  "xml/node.rb",
  "xml/dtd.rb",
  "xml/attr.rb",
  "xml/document.rb",
  "xml/document_fragment.rb",
  "xml/schema.rb",
  "xml/relax_ng.rb",
  "xml/text.rb",
  "xml/cdata.rb",
  "xml/comment.rb",
  "xml/processing_instruction.rb",
  "xml/node_set.rb",
  "xml/xpath.rb",
  "xml/xpath_context.rb",
  "xml/syntax_error.rb",
  "xml/reader.rb",
  "xml/entity_reference.rb",
  "xml/sax/parser.rb",
  "xml/sax/push_parser.rb",
  "html/document.rb",
  "html/element_description.rb",
  "html/entity_lookup.rb",
  "html/sax/parser.rb",
  "xslt/stylesheet.rb",
].each do |file|
  require File.join(File.dirname(__FILE__), file)
end
