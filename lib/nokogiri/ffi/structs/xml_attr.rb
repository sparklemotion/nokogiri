module Nokogiri
  module LibXML
    class XmlAttr < FFI::Struct

      layout(
        :_private,      :pointer,
        :type,          :int,
        :name,          :string,
        :children,      :pointer,
        :last,          :pointer,
        :parent,        :pointer,
        :next,          :pointer,
        :prev,          :pointer,
        :doc,           :pointer
        )

    end
  end
end    
