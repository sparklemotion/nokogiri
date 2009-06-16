module Nokogiri
  module XML
    ###
    # This class provides information about XML SyntaxErrors.  These
    # exceptions are typically stored on Nokogiri::XML::Document#errors.
    class SyntaxError < ::Nokogiri::SyntaxError
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

      alias :to_s :message
    end
  end
end
