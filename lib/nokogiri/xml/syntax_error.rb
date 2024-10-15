# frozen_string_literal: true

module Nokogiri
  module XML
    ###
    # This class provides information about XML SyntaxErrors.  These
    # exceptions are typically stored on Nokogiri::XML::Document#errors.
    class SyntaxError < ::Nokogiri::SyntaxError
      class << self
        def aggregate(errors)
          return nil if errors.empty?
          return errors.first if errors.length == 1

          messages = ["Multiple errors encountered:"]
          errors.each do |error|
            messages << error.to_s
          end
          new(messages.join("\n"))
        end
      end

      # What part of libxml2 raised this error (enum xmlErrorDomain)
      attr_reader :domain
      # libxml2 error code (enum xmlParserErrors)
      attr_reader :code
      # libxml2 error level (enum xmlErrorLevel)
      attr_reader :level
      attr_reader :file
      attr_reader :line
      # libxml2 path of the node in the tree that caused the error
      attr_reader :path
      # libxml2 extra string information
      attr_reader :str1
      # libxml2 extra string information
      attr_reader :str2
      # libxml2 extra string information
      attr_reader :str3
      # libxml2 extra extra number information
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
        message = super.chomp
        [location_to_s, level_to_s, message]
          .compact.join(": ")
          .force_encoding(message.encoding)
      end

      private

      def level_to_s
        case level
        when 3 then "FATAL"
        when 2 then "ERROR"
        when 1 then "WARNING"
        end
      end

      def nil_or_zero?(attribute)
        attribute.nil? || attribute.zero?
      end

      def location_to_s
        return if nil_or_zero?(line) && nil_or_zero?(column)

        "#{line}:#{column}"
      end
    end
  end
end
