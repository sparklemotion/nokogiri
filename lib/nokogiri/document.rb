module Nokogiri
  # Wraps xmlDocPtr
  class Document < Node
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
