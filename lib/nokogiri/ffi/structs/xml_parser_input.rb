module Nokogiri
  # :stopdoc:
  module LibXML
    class XmlParserInput < FFI::Struct
      layout(
        :buf,               :pointer,
        :filename,          :pointer,
        :directory,         :pointer,
        :base,              :pointer,
        :cur,               :pointer,
        :end,               :pointer,
        :length,            :int,
        :line,              :int,
        :col,               :int
      )
    end
  end
  # :startdoc:
end
