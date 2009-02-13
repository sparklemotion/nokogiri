# Modify the PATH on windows so that the external DLLs will get loaded.
ENV['PATH'] = [File.expand_path(
  File.join(File.dirname(__FILE__), "..", "ext", "nokogiri")
), ENV['PATH']].compact.join(';') if RUBY_PLATFORM =~ /mswin/i

require 'nokogiri/native' unless RUBY_PLATFORM =~ /java/

require 'nokogiri/version'
require 'nokogiri/syntax_error'
require 'nokogiri/xml'
require 'nokogiri/xslt'
require 'nokogiri/html'
require 'nokogiri/decorators'
require 'nokogiri/css'
require 'nokogiri/html/builder'
require 'nokogiri/hpricot'

module Nokogiri
  class << self
    ###
    # Parse an HTML or XML document.  +string+ contains the document.
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
        Nokogiri::HTML.fragment(input).children.first
      else
        Nokogiri(&blk)
      end
    end
    
    ###
    # Parse a document and add the Slop decorator.  The Slop decorator
    # implements method_missing such that methods may be used instead of CSS
    # or XPath.  For example:
    #
    #   doc = Nokogiri::Slop(<<-eohtml)
    #     <html>
    #       <body>
    #         <p>first</p>
    #         <p>second</p>
    #       </body>
    #     </html>
    #   eohtml
    #   assert_equal('second', doc.html.body.p[1].text)
    #
    def Slop(*args, &block)
      Nokogiri(*args, &block).slop!
    end
  end
end

def Nokogiri(*args, &block)
  if block_given?
    builder = Nokogiri::HTML::Builder.new(&block)
    return builder.doc.root
  else
    Nokogiri.parse(*args)
  end
end
