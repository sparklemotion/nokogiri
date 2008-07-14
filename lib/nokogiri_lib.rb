require 'mkmf'

module NokogiriLib
  extend DL::Importable
  dlload "libxml2.#{Config::CONFIG['DLEXT']}"
  extern "P xmlNewParserCtxt()"
  extern "I xmlParseDocument (P)"

  extern "P htmlCtxtReadMemory (P, c, I, c, c, I)"
  extern "P htmlReadMemory (S, I, c, c, I)"
  extern "I htmlParseDocument (P)"
  extern "P htmlCreateMemoryParserCtxt(c, I)"
  extern "P xmlCharStrdup(S)"

  module Tree
    extend DL::Importable
    dlload "libxml2.#{Config::CONFIG['DLEXT']}"
    extern "P xmlDocGetRootElement (P)" 
  end

  module Node
    extend DL::Importable
    dlload "libxml2.#{Config::CONFIG['DLEXT']}"
    extern "P xmlHasProp (P, P)" 
    extern "P xmlGetProp (P, P)" 
    extern "I xmlIsBlankNode (P)" 
  end
end
