module Nokogiri
  module XML
    class SyntaxError < ::StandardError
      def none?
        level == 0
      end

      def warning?
        level == 1
      end

      def error?
        level == 2
      end

      def fatal?
        level == 3
      end
    end
  end
end
