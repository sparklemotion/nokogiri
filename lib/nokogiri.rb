require 'nokogiri/version'
require 'nokogiri/xml'
require 'nokogiri/xslt'
require 'nokogiri/html'
require 'nokogiri/decorators'
require 'nokogiri/css'
require 'nokogiri/html/builder'
require 'nokogiri/hpricot'
require 'nokogiri/native'

module Nokogiri
  class << self
    attr_accessor :error_handler

    def parse string, url = nil, encoding = nil, options = nil
      doc =
        if string =~ /^\s*<[^Hh>]*html/i # Probably html
          Nokogiri::HTML.parse(string, url, encoding, options || 2145)
        else
          Nokogiri::XML.parse(string, url, encoding, options || 2159)
        end
      yield doc if block_given?
      doc
    end

    def make input = nil, opts = {}, &blk
      if input
        Nokogiri::XML::Node.new_from_str(input)
      else
        Nokogiri(&blk)
      end
    end
  end

  self.error_handler = lambda { |syntax_error| }
end

def Nokogiri(*args, &block)
  if block_given?
    builder = Nokogiri::HTML::Builder.new(&block)
    return builder.doc
  else
    Nokogiri::HTML.parse(*args)
  end
end
