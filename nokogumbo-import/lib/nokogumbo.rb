require 'nokogiri'
require 'nokogumboc'

module Nokogiri
  def self.HTML5(string)
    Nokogiri::HTML5.parse(string)
  end

  module HTML5
    def self.parse(string)
      # convert to UTF-8 (Ruby 1.9+) 
      if string.respond_to?(:encoding) and string.encoding != Encoding::UTF_8
        string = string.encode(Encoding::UTF_8)
      end

      Nokogumbo.parse(string)
    end
  end
end
