module Nokogiri
  module HTML
    class Document < XML::Document
      def serialize encoding = nil, options = XML::Node::FORMAT | XML::Node::AS_HTML
        super(encoding, options)
      end
    end
  end
end
