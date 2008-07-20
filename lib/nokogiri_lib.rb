require 'dl/import'
require 'mkmf'

module NokogiriLib
  begin
    extend DL::Importable
  rescue
    extend DL::Importer
  end
  dlload('libxml2.so') rescue dlload('libxml2.dylib')

  # Parser
  extern "void * htmlReadMemory (const char *, int, const char *, const char *, int)"
  extern "void * xmlReadMemory (const char *, int, const char *, const char *, int)"

  # Util
  extern "void * xmlCharStrdup(const char *)"

  # Tree
  extern "void * xmlDocGetRootElement (void *)"

  # Node
  extern "void * xmlHasProp (void *, void *)"
  extern "void * xmlGetProp (void *, void *)"
  extern "void * xmlSetProp (void *, void *, void*)"
  extern "int xmlIsBlankNode (void *)"
  extern "void * xmlNodeGetContent (void *)"
  extern "void * xmlGetNodePath (void *)"

  # XPath
  extern "void xmlXPathInit ()"
  extern "void * xmlXPathNewContext (void *)"
  extern "void * xmlXPathEvalExpression (void *, void *)"
  extern "void xmlXPathFreeObject(void *)"
end
