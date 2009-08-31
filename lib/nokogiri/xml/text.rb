module Nokogiri
  module XML
    class Text < Nokogiri::XML::Node
      def inspect
        "#<#{self.class.name}:#{sprintf("0x%x",object_id)} #{text.inspect} >"
      end
    end
  end
end
