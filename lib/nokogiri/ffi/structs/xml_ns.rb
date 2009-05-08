module Nokogiri
  module LibXML # :nodoc:
    class XmlNs < FFI::Struct # :nodoc:
      layout(
        :next,   :pointer,
        :type,   :int,
        :href,   :string,
        :prefix, :string
        )
    end
  end
end
