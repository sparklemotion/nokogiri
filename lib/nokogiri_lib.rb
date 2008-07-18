require 'mkmf'

module NokogiriLib
  extend DL::Importable
  dlload('libxml2.so') rescue dlload('libxml2.dylib')

  # Parser
  extern "P htmlReadMemory (S, I, c, c, I)"
  extern "P xmlReadMemory (S, I, c, c, I)"
  extern "P xmlNewParserCtxt()"
  extern "I xmlParseDocument (P)"

  extern "P htmlCtxtReadMemory (P, c, I, c, c, I)"
  extern "I htmlParseDocument (P)"
  extern "P htmlCreateMemoryParserCtxt(c, I)"
  extern "P xmlCharStrdup(S)"

  # Tree
  extern "P xmlDocGetRootElement (P)" 

  # Node
  extern "P xmlHasProp (P, P)" 
  extern "P xmlGetProp (P, P)" 
  extern "I xmlIsBlankNode (P)" 
end
