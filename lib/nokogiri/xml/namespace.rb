module Nokogiri
  module XML
    class Namespace
      attr_reader :document

      def inspect
        "#<#{self.class.name}:#{sprintf("0x%x", object_id)} prefix=#{prefix.inspect} href=#{href.inspect}>"
      end
    end
  end
end
