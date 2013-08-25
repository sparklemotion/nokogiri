require 'nokogiri'
require 'nokogumboc'

module Nokogiri
  def self.HTML5(string)
    Nokogiri::HTML5.parse(string)
  end

  module HTML5
    def self.parse(string)
      if string.respond_to? :read
        string = string.read
      end

      # convert to UTF-8 (Ruby 1.9+) 
      if string.respond_to?(:encoding) and string.encoding != Encoding::UTF_8
        string = reencode(string)
      end

      Nokogumbo.parse(string)
    end

    def self.get(uri, limit=10)
      require 'net/http'
      uri = URI(uri) unless URI === uri

      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true 
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      case response
      when Net::HTTPSuccess
        parse(reencode(response.body, response['content-type']))
      when Net::HTTPRedirection
        response.value if limit <= 1
        get(response['location'], limit-1)
      else
        response.value
      end
    end

  private

    # Charset sniffing is a complex and controversial topic that understandably
    # isn't done _by default_ by the Ruby Net::HTTP library.  This being said,
    # it is a very real problem for consumers of HTML as the default for HTML
    # is iso-8859-1, most "good" producers use utf-8, and the Gumbo parser
    # *only* supports utf-8.
    #
    # Accordingly, Nokogiri::HTML::Document.parse provides limited encoding
    # detection.  Following this lead, Nokogiri::HTML5 attempts to do likewise,
    # while attempting to more closely follow the HTML5 standard.
    #
    # http://bugs.ruby-lang.org/issues/2567
    # http://www.w3.org/TR/html5/syntax.html#determining-the-character-encoding
    #
    def self.reencode(body, content_type=nil)
      return body unless body.respond_to? :encoding

      if body.encoding == Encoding::ASCII_8BIT
        encoding = nil

        # look for a Byte Order Mark (BOM)
        if body[0..1] == "\xFE\xFF"
          encoding = 'utf-16be'
        elsif body[0..1] == "\xFF\xFE"
          encoding = 'utf-16le'
        elsif body[0..2] == "\xEF\xBB\xBF"
          encoding = 'utf-8'
        end

        # look for a charset in a content-encoding header
        if content_type
          encoding ||= content_type[/charset=(.*?)($|\s|;)/i, 1]
        end

        # look for a charset in a meta tag in the first 1024 bytes
        if not encoding
          data = body[0..1023].gsub(/<!--.*?(-->|\Z)/m, '')
          data.scan(/<meta.*?>/m).each do |meta|
            encoding ||= meta[/charset=["']?([^>]*?)($|["'\s>])/im, 1]
          end
        end

        # if all else fails, default to the official default encoding for HTML
        encoding ||= Encoding::ISO_8859_1

        # change the encoding to match the detected or inferred encoding
        body.force_encoding(encoding)
      end

      body.encode(Encoding::UTF_8)
    end
  end
end
