require 'nokogiri/version'
require 'nokogiri/xml'
require 'nokogiri/xslt'
require 'nokogiri/html'
require 'nokogiri/decorators'
require 'nokogiri/xml/builder'
require 'nokogiri/html/builder'
require 'nokogiri/hpricot'
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

    def XML(string)
      Nokogiri::XML.parse(string)
    end
  end
end

def Nokogiri(*args, &block)
  if block_given?
    builder = Nokogiri::HTML::Builder.new
    builder.instance_eval(&block)
    return builder.doc
  else
    Nokogiri::HTML.parse(*args)
  end
end
