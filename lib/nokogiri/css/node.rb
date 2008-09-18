module Nokogiri
  module CSS
    class Node
      attr_accessor :type, :value
      def initialize type, value
        @type = type
        @value = value
      end

      def accept visitor
        visitor.send(:"visit_#{type.to_s.downcase}", self)
      end

      def to_xpath prefix = '//'
        prefix + XPathVisitor.new.accept(self)
      end
    end
  end
end
