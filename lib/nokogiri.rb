require 'dl/import'
require 'nokogiri_lib'
require 'nokogiri/node'
require 'nokogiri/document'

module Nokogiri
  VERSION = '1.0.0'

  class << self
    def parse(string, url = nil, encoding = nil, options = 1)
      doc = NokogiriLib.htmlReadMemory(
        string,
        string.length,
        url || 0,
        encoding || 0,
        options
      )
      Document.new(doc)
    end
  end
end
