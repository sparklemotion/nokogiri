require 'dl/import'
require 'nokogiri_lib'
require 'nokogiri/node'
require 'nokogiri/document'

module Nokogiri
  VERSION = '1.0.0'

  class << self
    def parse(string, url = nil, encoding = nil, options = 32)
      doc =
        if string =~ /^\s*<[^Hh>]*html/i # Probably html
          NokogiriLib.htmlReadMemory(
                                     string,
                                     string.length,
                                     url || 0,
                                     encoding || 0,
                                     options
                                    )
        else
          NokogiriLib.xmlReadMemory(
                                     string,
                                     string.length,
                                     url || 0,
                                     encoding || 0,
                                     options
                                    )
        end
      doc = Document.wrap(doc)
      yield doc if block_given?
      doc
    end
  end
end
