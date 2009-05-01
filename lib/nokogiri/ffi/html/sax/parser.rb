module Nokogiri
  module HTML
    module SAX
      class Parser < XML::SAX::Parser
        
        def native_parse_file(data, encoding)
          docptr = LibXML.htmlSAXParseFile(data, encoding, cstruct, nil)
          LibXML.xmlFreeDoc docptr
          data
        end

        def native_parse_memory(data, encoding)
          docptr = LibXML.htmlSAXParseDoc(data, encoding, cstruct, nil)
          LibXML.xmlFreeDoc docptr
          data
        end

      end
    end
  end
end
