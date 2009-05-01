module Nokogiri
  # The version of Nokogiri you are using
  VERSION = '1.2.3'

  # More complete version information about libxml
  VERSION_INFO = {}
  VERSION_INFO['warnings']              = []
  VERSION_INFO['nokogiri']              = VERSION
  if defined?(LIBXML_VERSION) && ! defined?(FFI)
    VERSION_INFO['libxml']              = {}
    VERSION_INFO['libxml']['binding']   = 'extension'
    VERSION_INFO['libxml']['compiled']  = LIBXML_VERSION

    match = LIBXML_PARSER_VERSION.match(/(\d)(\d{2})(\d{2})/)
    VERSION_INFO['libxml']['loaded']    = "#{match[1].to_i}.#{match[2].to_i}.#{match[3].to_i}"

    if VERSION_INFO['libxml']['compiled'] != VERSION_INFO['libxml']['loaded']
      warning = "Nokogiri was built against LibXML version #{VERSION_INFO['libxml']['compiled']}, but has dynamically loaded #{VERSION_INFO['libxml']['loaded']}"
      VERSION_INFO['warnings'] << warning
      warn "WARNING: #{warning}"
    end
  end

  def Nokogiri.ffi?
    Nokogiri::VERSION_INFO['libxml']['binding'] == 'ffi'
  end
end
