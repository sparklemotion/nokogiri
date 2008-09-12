require 'dl/import'
require 'dl/struct'
require 'mkmf'

require 'nokogiri/version'
require 'nokogiri/dl/xml'
require 'nokogiri/dl/xslt'
require 'nokogiri/xml'
require 'nokogiri/xslt'
require 'nokogiri/html'
require 'nokogiri/native'

module Nokogiri

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
