module Nokogiri
  module HTML
    class Document < XML::Document
      def serialize encoding = nil, options = 1 & 64
        super(encoding, options)
      end
    end
  end
end
