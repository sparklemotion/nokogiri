module Nokogiri
  module HTML
    class Document < XML::Document
      alias :to_html :serialize
    end
  end
end
