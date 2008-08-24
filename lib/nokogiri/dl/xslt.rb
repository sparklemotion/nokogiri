module Nokogiri
  module DL
    module XSLT
      begin
        extend ::DL::Importable
        DL_VERSION = 'dl'
      rescue
        extend ::DL::Importer
        DL_VERSION = 'dl2'
      end

      dlload('libxslt.so') rescue dlload('libxslt.dylib')
      Stylesheet = struct [
        'void * parent',
        'void * next',
        'void * imports',
      ]
      Params = struct [
        'char params[17]',
      ]
      extern "void * xsltParseStylesheetDoc (void *)"
      extern "void * xsltApplyStylesheet (void *, void *, const char **)"
      extern "void * xsltSaveResultToString (void *, int *, void *, void *)"
    end
  end
end
