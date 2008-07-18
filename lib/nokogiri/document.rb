module Nokogiri
  # Wraps xmlDocPtr
  class Document < Node
    def search(path)
      xpath_ctx = NokogiriLib.xmlXPathNewContext(ptr)
      xpath_obj = NokogiriLib.xmlXPathEvalExpression(
        NokogiriLib.xmlCharStrdup(path),
        xpath_ctx
      )
      xpath_obj.struct!('PP', :type, :nodeset)
      NodeSet.wrap(xpath_obj[:nodeset], xpath_ctx)
    end

    def root
      Node.wrap(NokogiriLib.xmlDocGetRootElement(ptr))
    end

    def xml?
      ptr[:type] == XML_DOCUMENT_NODE
    end

    def html?
      ptr[:type] == XML_HTML_DOCUMENT_NODE
    end
  end
end
