require 'dl/import'
require 'nokogiri_lib'
require 'nokogiri/node'
require 'nokogiri/document'
require 'nokogiri/xml'
require 'nokogiri/html'

module Nokogiri
  VERSION = '1.0.0'

  class << self
    def parse(string, url = nil, encoding = nil, options = 32)
      doc =
        if string =~ /^\s*<[^Hh>]*html/i # Probably html
          Nokogiri::HTML.parse(string, url, encoding, options)
        else
          Nokogiri::XML.parse(string, url, encoding, options)
        end
      yield doc if block_given?
      doc
    end
  end
end
