module Nokogiri
  module CSS
    class Parser < GeneratedTokenizer
      class << self
        def parse string
          new.parse(string)
        end
      end
      alias :parse :scan_str
    end
  end
end
