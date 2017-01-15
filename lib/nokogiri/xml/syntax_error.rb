module Nokogiri
  module XML
    ###
    # This class provides information about XML SyntaxErrors.  These
    # exceptions are typically stored on Nokogiri::XML::Document#errors.
    class SyntaxError < ::Nokogiri::SyntaxError
      attr_reader :domain
      attr_reader :code
      attr_reader :level
      attr_reader :file
      attr_reader :line
      attr_reader :str1
      attr_reader :str2
      attr_reader :str3
      attr_reader :int1
      attr_reader :column

      ###
      # return true if this is a non error
      def none?
        level == 0
      end

      ###
      # return true if this is a warning
      def warning?
        level == 1
      end

      ###
      # return true if this is an error
      def error?
        level == 2
      end

      ###
      # return true if this error is fatal
      def fatal?
        level == 3
      end

      def to_s
        [location_to_s, level_to_s, super.chomp].compact.join(": ")
      end

      private

      def level_to_s
        case level
        when 3 then "FATAL"
        when 2 then "ERROR"
        when 1 then "WARNING"
        else nil
        end
      end

      def location_to_s
        return nil if line.nil? && column.nil?
        "#{line}:#{column}"
      end
    end
  end
end
