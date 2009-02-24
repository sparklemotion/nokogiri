module Nokogiri
  module XML
    module SAX
      class Parser
        ENCODINGS = {
          'NONE'        => 0, # No char encoding detected
          'UTF-8'       => 1, # UTF-8
          'UTF16LE'     => 2, # UTF-16 little endian
          'UTF16BE'     => 3, # UTF-16 big endian
          'UCS4LE'      => 4, # UCS-4 little endian
          'UCS4BE'      => 5, # UCS-4 big endian
          'EBCDIC'      => 6, # EBCDIC uh!
          'UCS4-2143'   => 7, # UCS-4 unusual ordering
          'UCS4-3412'   => 8, # UCS-4 unusual ordering
          'UCS2'        => 9, # UCS-2
          'ISO-8859-1'  => 10, # ISO-8859-1 ISO Latin 1
          'ISO-8859-2'  => 11, # ISO-8859-2 ISO Latin 2
          'ISO-8859-3'  => 12, # ISO-8859-3
          'ISO-8859-4'  => 13, # ISO-8859-4
          'ISO-8859-5'  => 14, # ISO-8859-5
          'ISO-8859-6'  => 15, # ISO-8859-6
          'ISO-8859-7'  => 16, # ISO-8859-7
          'ISO-8859-8'  => 17, # ISO-8859-8
          'ISO-8859-9'  => 18, # ISO-8859-9
          'ISO-2022-JP' => 19, # ISO-2022-JP
          'SHIFT-JIS'   => 20, # Shift_JIS
          'EUC-JP'      => 21, # EUC-JP
          'ASCII'       => 22, # pure ASCII
        }

        attr_accessor :document
        def initialize(doc = XML::SAX::Document.new)
          @encoding = 'ASCII'
          @document = doc
        end

        ###
        # Parse given +thing+ which may be a string containing xml, or an
        # IO object.
        def parse thing
          if thing.respond_to?(:read) && thing.respond_to?(:close)
            parse_io(thing)
          else
            parse_memory(thing)
          end
        end

        ###
        # Parse given +io+
        def parse_io io, encoding = 'ASCII'
          @encoding = encoding
          native_parse_io io, ENCODINGS[@encoding] || ENCODINGS['ASCII']
        end

        ###
        # Parse a file with +filename+
        def parse_file filename
          raise Errno::ENOENT unless File.exists?(filename)
          raise Errno::EISDIR if File.directory?(filename)
          native_parse_file filename
        end
      end
    end
  end
end
