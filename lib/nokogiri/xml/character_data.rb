module Nokogiri
  module XML
    class CharacterData < Nokogiri::XML::Node
      include Nokogiri::XML::PP::CharacterData

      def inspect
        "#<#{self.class.name}:#{sprintf("0x%x",object_id)} #{text.inspect}>"
      end
    end
  end
end
