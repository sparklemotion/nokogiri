module Nokogiri
  module XML
    class ElementDecl < Nokogiri::XML::Node
      undef_method :namespace
      undef_method :namespace_definitions
      undef_method :line

      # FIXME we need an element content method, but I don't want to implement
      # it right now.
      undef_method :content
    end
  end
end
