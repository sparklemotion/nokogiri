module Nokogiri
  module HTML
    class Builder < XML::Builder
      def initialize
        @doc = Nokogiri::HTML::Document.new
      end
    end
  end
end
