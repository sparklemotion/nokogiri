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

      def find_by_type(types)
        matches = []
        matches << self if to_type == types
        @value.each do |v|
          matches += v.find_by_type(types) if v.respond_to?(:find_by_type)
        end
        matches
      end

      def to_type
        [@type] + @value.map { |n|
          n.to_type if n.respond_to?(:to_type)
        }.compact
      end

      def to_a
        [@type] + @value.map { |n| n.to_a }
      end
    end
  end
end
