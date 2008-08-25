module Nokogiri
  module DL
    module XML
      begin
        extend ::DL::Importable
        DL_VERSION = 'dl'
      rescue
        extend ::DL::Importer
        DL_VERSION = 'dl2'
      end
      class << self; def dl2?; DL_VERSION == 'dl2'; end end

      dlload('libxml2.so') rescue dlload('libxml2.dylib')

      # Parser
      extern "void * htmlReadMemory (const char *, int, const char *, const char *, int)"
      extern "void * xmlReadMemory (const char *, int, const char *, const char *, int)"

      # Util
      extern "void * xmlCharStrdup(const char *)"

      # Tree
      extern "void * xmlDocGetRootElement (void *)"
      extern "void * xmlDocSetRootElement (void *, void *)"
      extern "void * xmlNewDoc (void *)"
      extern "void * htmlNewDoc (void *, void *)"
      extern "void * htmlDocDumpMemory (void *, void *, int *)"
      extern "void * xmlDocDumpMemory (void *, void *, int *)"

      # Node
      Node = struct [
        'void * private',
        'int type',
        'char * name',
        'void * children',
        'void * last',
        'void * parent',
        'void * next',
        'void * prev',
        'void * doc',
      ]
      NodeSet = struct [
        'int length',
        'int max',
        'void * node_ptr',
      ]
      extern "void * xmlHasProp (void *, void *)"
      extern "void * xmlGetProp (void *, void *)"
      extern "void * xmlSetProp (void *, void *, void*)"
      extern "int xmlIsBlankNode (void *)"
      extern "void * xmlNodeGetContent (void *)"
      extern "void * xmlGetNodePath (void *)"
      extern "void * xmlNewNode (void *, void *)"
      extern "void xmlNodeSetContent (void *, void *)"

      # XPath
      XPath = struct [
        'void * type',
        'void * nodeset',
      ]
      extern "void xmlXPathInit ()"
      extern "void * xmlXPathNewContext (void *)"
      extern "void * xmlXPathEvalExpression (void *, void *)"
      extern "void xmlXPathFreeObject(void *)"

      # Misc
      extern "int xmlSubstituteEntitiesDefault (int)"
      LOAD_EXT_DTD = (struct(['int value'])).new(symbol("xmlLoadExtDtdDefaultValue"))
    end
  end
end
