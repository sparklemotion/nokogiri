module Nokogiri
  module LibXML

    class XmlXpathParserContext < FFI::Struct

      layout(
        :cur,     :pointer,
        :base,    :pointer,
        :error,   :int,
        :context, :pointer
        )

      def context
        p = self[:context]
        LibXML::XmlXpathContextCast.new(p)
      end
    end

  end
end
