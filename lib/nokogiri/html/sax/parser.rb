module Nokogiri
  module HTML
    module SAX
      class Parser < XML::SAX::Parser
        ###
        # Parse html stored in +data+ using +encoding+
        def parse_memory data, encoding = 'UTF-8'
          native_parse_memory(data, encoding)
        end

        ###
        # Parse a file with +filename+
        def parse_file filename, encoding = 'UTF-8'
          raise Errno::ENOENT unless File.exists?(filename)
          raise Errno::EISDIR if File.directory?(filename)
          native_parse_file filename, encoding
        end
      end
    end
  end
end
