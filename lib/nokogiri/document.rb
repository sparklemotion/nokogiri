module Nokogiri
  class Document
    def initialize(ptr)
      @ptr = ptr
    end

    def root
      Node.new(NokogiriLib::Tree.xmlDocGetRootElement(@ptr))
    end
  end
end
