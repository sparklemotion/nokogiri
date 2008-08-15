require 'dl/import'
require 'dl/struct'
require 'mkmf'

module NokogiriLib
  begin
    extend DL::Importable
    DL = 'dl'
  rescue
    extend DL::Importer
    DL = 'dl2'
  end
  class << self; def dl2?; DL == 'dl2'; end end

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
end
