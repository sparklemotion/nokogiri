module Nokogiri
  module XSLT
    class Stylesheet

      attr_accessor :cstruct

      def self.parse_stylesheet_doc(document)
        LibXML.exsltRegisterAll
        ss = LibXML.xsltParseStylesheetDoc(LibXML.xmlCopyDoc(document.cstruct, 1)) # 1 => recursive

        obj = allocate
        obj.cstruct = LibXML::XsltStylesheet.new(ss)
        obj
      end

      def serialize(document)
        buf_ptr = FFI::MemoryPointer.new :pointer
        buf_len = FFI::MemoryPointer.new :int
        LibXML.xsltSaveResultToString(buf_ptr, buf_len, document.cstruct, cstruct)
        buf = Nokogiri::LibXML::XmlAlloc.new(buf_ptr.read_pointer)
        buf.pointer.read_string(buf_len.read_int)
      end

      def transform(document, params=[])
        param_arr = FFI::MemoryPointer.new(:pointer, params.length + 1)
        params.each_with_index do |param, j|
          param_arr[j].put_pointer(0, FFI::MemoryPointer.from_string(param.to_s))
        end
        param_arr[params.length].put_pointer(0,nil)

        ptr = LibXML.xsltApplyStylesheet(cstruct, document.cstruct, param_arr)
        XML::Document.wrap(ptr)
      end

    end
  end
end
