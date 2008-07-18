module Nokogiri
  class Document
    def initialize(ptr)
      @ptr = ptr
    end

    def root
      Node.new(NokogiriLib.xmlDocGetRootElement(@ptr))
    end
  end
end
