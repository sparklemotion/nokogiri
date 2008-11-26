require 'nokogiri/version'
require 'nokogiri/xml'
require 'nokogiri/xslt'
require 'nokogiri/html'
require 'nokogiri/decorators'
require 'nokogiri/css'
require 'nokogiri/html/builder'
require 'nokogiri/hpricot'

# Modify the PATH on windows so that the external DLLs will get loaded.
ENV['PATH'] = [File.expand_path(
  File.join(File.dirname(__FILE__), "..", "ext", "nokogiri")
), ENV['PATH']].compact.join(';') if RUBY_PLATFORM =~ /mswin/i

require 'nokogiri/native' unless RUBY_PLATFORM =~ /java/

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
    
    def Slop(*args, &block)
      Nokogiri(*args, &block).slop!
    end
  end

  self.error_handler = lambda { |syntax_error| }  
end

def Nokogiri(*args, &block)
  if block_given?
    builder = Nokogiri::HTML::Builder.new(&block)
    return builder.doc
  else
    Nokogiri.parse(*args)
  end
end
