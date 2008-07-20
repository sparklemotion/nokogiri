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
  extern "void * xmlDocSetRootElement (void *, void *)"
  extern "void * xmlNewDoc (void *)"
  extern "void * htmlNewDoc (void *, void *)"
  extern "void * htmlDocDumpMemory (void *, void *, int *)"
  extern "void * xmlDocDumpMemory (void *, void *, int *)"

  # Node
  extern "void * xmlHasProp (void *, void *)"
  extern "void * xmlGetProp (void *, void *)"
  extern "void * xmlSetProp (void *, void *, void*)"
  extern "int xmlIsBlankNode (void *)"
  extern "void * xmlNodeGetContent (void *)"
  extern "void * xmlGetNodePath (void *)"
  extern "void * xmlNewNode (void *, void *)"
  extern "void xmlNodeSetContent (void *, void *)"

  # XPath
  extern "void xmlXPathInit ()"
  extern "void * xmlXPathNewContext (void *)"
  extern "void * xmlXPathEvalExpression (void *, void *)"
  extern "void xmlXPathFreeObject(void *)"
end
