module Nokogiri
  module HTML
    class Document < XML::Document
      ####
      # Serialize this Document with +encoding+ using +options+
      def serialize encoding = nil, options = XML::Node::SaveOptions::FORMAT |
        XML::Node::SaveOptions::AS_HTML |
        XML::Node::SaveOptions::NO_DECLARATION |
        XML::Node::SaveOptions::NO_EMPTY_TAGS

        super(encoding, options)
      end
    end
  end
end
